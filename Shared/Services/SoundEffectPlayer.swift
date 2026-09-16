import AVFoundation
import AudioToolbox

/// Plays short UI sound effects (message sent/received, lock-screen alert),
/// each paired with a vibration. Kept as its own player instance, separate from
/// PlaybackSequencer's, so triggering an effect never interrupts or reloads
/// whichever voice message is currently loaded/playing.
final class SoundEffectPlayer {
    enum Effect: String {
        case messageReceived = "message_received"
        case messageSent = "message_sent"
        case lockScreenAlert = "alert"
    }

    static let shared = SoundEffectPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    func play(_ effect: Effect) {
        if effect != .messageSent {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }

        guard let url = Self.resourceURL(named: effect.rawValue) else {
            assertionFailure("Missing sound effect: \(effect.rawValue) — add it to Resources/Audio")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
        } catch {
            assertionFailure("Failed to play sound effect \(effect.rawValue): \(error)")
        }
    }

    private static func resourceURL(named name: String) -> URL? {
        let extensions = ["m4a", "caf", "wav", "mp3", "aiff"]
        return extensions.lazy.compactMap { Bundle.main.url(forResource: name, withExtension: $0) }.first
    }
}
