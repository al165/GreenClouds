import Foundation
import AVFoundation

/// Records a voice message to a temporary file. One recording at a time — starting
/// a new one implicitly abandons any in-flight state from a previous call.
final class VoiceRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0

    /// Below this, a recording is treated as an accidental tap rather than a real
    /// message and is discarded instead of sent.
    private let minimumDuration: TimeInterval = 0.5

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var pendingURL: URL?

    /// Requests microphone permission if needed, then starts recording. No-op if
    /// already recording or if permission is denied.
    func startRecording() {
        guard !isRecording else { return }

        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            beginRecording()
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.beginRecording() }
            }
        case .denied:
            break
        @unknown default:
            break
        }
    }

    /// Stops recording and returns the file + duration to send, or nil if it was too
    /// short to count as a real message (the temp file is cleaned up either way).
    @discardableResult
    func finishRecording() -> (url: URL, duration: TimeInterval)? {
        guard isRecording, let recorder, let pendingURL else { return nil }
        let duration = recorder.currentTime
        stopTimer()
        recorder.stop()
        isRecording = false
        self.recorder = nil
        self.pendingURL = nil

        guard duration >= minimumDuration else {
            try? FileManager.default.removeItem(at: pendingURL)
            return nil
        }
        return (pendingURL, duration)
    }

    /// Stops recording and discards it — used when the user drags away to cancel.
    func cancelRecording() {
        guard isRecording else { return }
        stopTimer()
        recorder?.stop()
        recorder = nil
        isRecording = false
        if let pendingURL {
            try? FileManager.default.removeItem(at: pendingURL)
        }
        pendingURL = nil
        elapsed = 0
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.record()
            recorder = newRecorder
            pendingURL = url
            isRecording = true
            elapsed = 0
            startTimer()
        } catch {
            assertionFailure("Failed to start voice recording: \(error)")
        }
    }

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder else { return }
            self.elapsed = recorder.currentTime
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
