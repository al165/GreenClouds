import SwiftUI

/// GC Performance's root: the chat is visible immediately, with no lock screen —
/// this is the performer's own control surface, not a prop pretending to be a
/// stranger's phone.
///
/// The performer's own first sent message starts the scripted sequence (whatever
/// they type — it's just the trigger). Sending exactly "reset" clears the chat and
/// the sequencer back to the start, ready for another run.
struct PerformanceRootView: View {
    @StateObject private var sequencer = PlaybackSequencer()
    @State private var timeline: [ChatItem] = []
    @State private var hasStarted = false

    private let resetCommand = "reset"

    var body: some View {
        ChatView(sequencer: sequencer, timeline: $timeline, onBeforeSend: handleBeforeSend, onDidSend: handleDidSend)
            .onAppear {
                sequencer.onStepRevealed = { step, duration in
                    timeline.append(.script(RevealedScriptStep(step: step, duration: duration)))
                    // Only voice messages get the received sound, not text or photos.
                    if case .voice = step.kind {
                        SoundEffectPlayer.shared.play(.messageReceived)
                    }
                }
            }
    }

    /// Returns true if the message was fully handled here (the "reset" command), so
    /// ChatView shouldn't also append it as a normal outgoing bubble.
    private func handleBeforeSend(_ text: String) -> Bool {
        guard text.caseInsensitiveCompare(resetCommand) == .orderedSame else { return false }
        sequencer.reset()
        timeline = []
        hasStarted = false
        return true
    }

    /// Starts the sequence right after the performer's first real message (typed or
    /// voice) has been appended, so the scripted reply appears after it — with the
    /// normal "sending…" status first, same as every other step. If that first message
    /// is a voice message, the sequence holds off until it's been played back to the
    /// end (by a tap on its play button), and the first step's `preDelay` counts down
    /// from then.
    private func handleDidSend(_ message: SentMessage) {
        guard !hasStarted else { return }
        hasStarted = true
        if case .voice = message.content {
            sequencer.start(skipFirstSendingPhase: false, afterReplayOf: message.id)
        } else {
            sequencer.start(skipFirstSendingPhase: false)
        }
    }
}
