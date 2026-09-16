import Foundation

/// What a script step actually shows once revealed.
enum ScriptStepKind {
    /// Plays Resources/Audio/<audioFileName>.m4a as a voice-note bubble.
    case voice(audioFileName: String)
    /// A plain text bubble.
    case text(String)
    /// A photo bubble. `imageName` must exist in Assets.xcassets; `caption` is optional.
    case image(imageName: String, caption: String? = nil)

    /// Shown in place of "online" in the chat header while this step is being "sent".
    var activityText: String {
        switch self {
        case .voice: return "recording audio…"
        case .text: return "typing…"
        case .image: return "sending photo…"
        }
    }
}

/// One step in the scripted message sequence.
struct ScriptStep: Identifiable {
    let id = UUID()
    let kind: ScriptStepKind
    /// true = bubble appears on the left, as if sent by the contact.
    let isFromContact: Bool
    /// Pause before the next step begins — after the audio finishes for a voice
    /// step, or right after reveal for a text/image step (which has no natural
    /// "playback" to wait on).
    let postDelay: TimeInterval

    init(kind: ScriptStepKind, isFromContact: Bool = true, postDelay: TimeInterval = 1.2) {
        self.kind = kind
        self.isFromContact = isFromContact
        self.postDelay = postDelay
    }
}
