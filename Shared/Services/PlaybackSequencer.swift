import Foundation
import AVFoundation

/// Drives the scripted sequence. Each step goes through two phases before advancing:
/// a brief "sending" phase (a transient status bubble, no audio loaded yet), then the
/// voice bubble itself — loaded but *not* auto-playing; the audience member must tap
/// it to start. Advancing to the next step only happens once that playback finishes
/// naturally (plus its postDelay) — there's no way for the audience to skip ahead or
/// go back. A put-down (reset()) at any point stops everything and clears back to the
/// start. `skipToEnd()` is a rehearsal/dev-only escape hatch (see VoiceMessageBubble's
/// secret long-press) so a run-through doesn't require sitting through every message.
final class PlaybackSequencer: NSObject, ObservableObject {
    @Published private(set) var currentlyPlayingStepID: UUID?
    @Published private(set) var isPaused = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    /// Non-nil while the "Sending voice message…" status is showing for this step.
    @Published private(set) var preparingStep: ScriptStep?
    /// True once the last script step's postDelay has elapsed with nothing left to
    /// advance to — the performance is over, shown as the contact going "offline".
    @Published private(set) var isFinished = false

    /// Independent playback state for replaying an already-completed voice message —
    /// kept separate from the live step above so re-listening to an old message never
    /// disturbs the sequence's own progression/advance timing.
    @Published private(set) var replayingStepID: UUID?
    @Published private(set) var isReplayPaused = true
    @Published private(set) var replayCurrentTime: TimeInterval = 0

    /// Called once a step's voice bubble is actually ready to display (after the
    /// sending phase), with its resolved audio duration.
    var onStepRevealed: ((ScriptStep, TimeInterval) -> Void)?

    private var player: AVAudioPlayer?
    private var currentIndex = 0
    private var isRunning = false
    private var pendingAdvance: DispatchWorkItem?
    private var pendingSend: DispatchWorkItem?
    private var progressTimer: Timer?

    private var replayPlayer: AVAudioPlayer?
    private var replayProgressTimer: Timer?

    /// How long the "Sending voice message…" status shows before the bubble appears.
    private let sendingDuration: TimeInterval = 2.0

    /// Starts the sequence. By default the first step skips the "sending" phase and
    /// appears immediately — appropriate for GC Installation, where the lock-screen
    /// notification already represented it arriving. Pass `skipFirstSendingPhase:
    /// false` (GC Performance, started by the performer's own first sent message) to
    /// have the first step go through the normal "sending…" status like every other.
    func start(skipFirstSendingPhase: Bool = true) {
        guard !isRunning else { return }
        isRunning = true
        isFinished = false
        currentIndex = 0
        if skipFirstSendingPhase {
            loadCurrentStep()
        } else {
            prepareNextStep()
        }
    }

    func reset() {
        isRunning = false
        isPaused = false
        isFinished = false
        pendingAdvance?.cancel()
        pendingAdvance = nil
        pendingSend?.cancel()
        pendingSend = nil
        preparingStep = nil
        stopProgressTimer()
        player?.stop()
        player = nil
        currentlyPlayingStepID = nil
        currentTime = 0
        duration = 0
        currentIndex = 0

        stopReplayProgressTimer()
        replayPlayer?.stop()
        replayPlayer = nil
        replayingStepID = nil
        replayCurrentTime = 0
        isReplayPaused = true
    }

    /// Starts playback the first time it's tapped, or pauses/resumes it after that.
    /// No-op if nothing is currently loaded (e.g. tapping a completed, earlier bubble).
    func togglePlayPause() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPaused = true
            stopProgressTimer()
        } else {
            pauseReplayIfPlaying()
            player.play()
            isPaused = false
            startProgressTimer()
        }
    }

    /// Plays/pauses an already-completed voice message again, from the start on first
    /// tap. Fully independent of the live sequence step — it never affects `currentIndex`
    /// or scheduling the next advance.
    func toggleReplay(for step: ScriptStep) {
        guard case .voice(let audioFileName) = step.kind else { return }
        guard let url = Bundle.main.url(forResource: audioFileName, withExtension: "m4a") else {
            assertionFailure("Missing audio file: \(audioFileName).m4a — add it to Resources/Audio")
            return
        }
        toggleReplay(id: step.id, url: url)
    }

    /// Plays/pauses a user-recorded voice message (one someone sent themselves, from
    /// a file on disk) — same independent replay mechanism as the overload above.
    func toggleReplay(id: UUID, url: URL) {
        if replayingStepID == id, let replayPlayer {
            if replayPlayer.isPlaying {
                replayPlayer.pause()
                isReplayPaused = true
                stopReplayProgressTimer()
            } else {
                pauseLiveIfPlaying()
                replayPlayer.play()
                isReplayPaused = false
                startReplayProgressTimer()
            }
            return
        }

        do {
            pauseLiveIfPlaying()
            stopReplayProgressTimer()
            replayPlayer?.stop()

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            replayPlayer = newPlayer
            replayingStepID = id
            replayCurrentTime = 0
            newPlayer.play()
            isReplayPaused = false
            startReplayProgressTimer()
        } catch {
            assertionFailure("Failed to play voice message at \(url): \(error)")
        }
    }

    private func pauseLiveIfPlaying() {
        guard let player, player.isPlaying else { return }
        player.pause()
        isPaused = true
        stopProgressTimer()
    }

    private func pauseReplayIfPlaying() {
        guard let replayPlayer, replayPlayer.isPlaying else { return }
        replayPlayer.pause()
        isReplayPaused = true
        stopReplayProgressTimer()
    }

    /// Jumps the current voice message to just before its end so it finishes (and the
    /// sequence advances) almost immediately, without playing the rest out loud.
    /// Dev-only escape hatch — not reachable through normal audience interaction.
    func skipToEnd() {
        guard let player, isRunning else { return }
        pauseReplayIfPlaying()
        player.currentTime = max(0, player.duration - 0.05)
        currentTime = player.currentTime
        if !player.isPlaying {
            player.play()
            isPaused = false
            startProgressTimer()
        }
    }

    private func prepareNextStep() {
        guard isRunning, currentIndex < Script.steps.count else {
            if isRunning { isFinished = true }
            isRunning = false
            return
        }

        let step = Script.steps[currentIndex]
        preparingStep = step

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isRunning else { return }
            self.preparingStep = nil
            self.loadCurrentStep()
        }
        pendingSend = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + sendingDuration, execute: workItem)
    }

    private func loadCurrentStep() {
        guard isRunning, currentIndex < Script.steps.count else {
            if isRunning { isFinished = true }
            isRunning = false
            return
        }

        let step = Script.steps[currentIndex]

        switch step.kind {
        case .voice(let audioFileName):
            loadVoiceStep(step, audioFileName: audioFileName)
        case .text, .image:
            // No audio to wait on — reveal immediately and advance after postDelay.
            currentlyPlayingStepID = nil
            duration = 0
            currentTime = 0
            onStepRevealed?(step, 0)
            scheduleAdvance(after: step.postDelay)
        }
    }

    private func loadVoiceStep(_ step: ScriptStep, audioFileName: String) {
        guard let url = Bundle.main.url(forResource: audioFileName, withExtension: "m4a") else {
            assertionFailure("Missing audio file: \(audioFileName).m4a — add it to Resources/Audio")
            onStepRevealed?(step, 0)
            scheduleAdvance(after: step.postDelay)
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            player = newPlayer
            currentlyPlayingStepID = step.id
            duration = newPlayer.duration
            currentTime = 0
            isPaused = true // loaded and ready, but waiting for a manual tap to start
            onStepRevealed?(step, newPlayer.duration)
        } catch {
            onStepRevealed?(step, 0)
            scheduleAdvance(after: step.postDelay)
        }
    }

    private func startProgressTimer() {
        stopProgressTimer()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func startReplayProgressTimer() {
        stopReplayProgressTimer()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let replayPlayer = self.replayPlayer else { return }
            self.replayCurrentTime = replayPlayer.currentTime
        }
        RunLoop.main.add(timer, forMode: .common)
        replayProgressTimer = timer
    }

    private func stopReplayProgressTimer() {
        replayProgressTimer?.invalidate()
        replayProgressTimer = nil
    }

    private func scheduleAdvance(after delay: TimeInterval) {
        guard isRunning else { return }
        currentlyPlayingStepID = nil
        stopProgressTimer()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isRunning else { return }
            self.currentIndex += 1
            self.prepareNextStep()
        }
        pendingAdvance = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}

extension PlaybackSequencer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === replayPlayer {
            replayCurrentTime = replayPlayer?.duration ?? replayCurrentTime
            isReplayPaused = true
            stopReplayProgressTimer()
            return
        }

        guard isRunning, currentIndex < Script.steps.count else { return }
        currentTime = duration
        scheduleAdvance(after: Script.steps[currentIndex].postDelay)
    }
}
