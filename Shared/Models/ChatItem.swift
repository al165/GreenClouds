import Foundation

/// A script step once revealed. `duration` is only meaningful for voice steps
/// (captured at load time, so a completed bubble can still show its correct
/// length after the sequencer moves on) — text/image steps just leave it 0.
struct RevealedScriptStep: Identifiable {
    let step: ScriptStep
    let duration: TimeInterval
    let sentAt: Date = Date()
    var id: UUID { step.id }
}

/// A message the audience member typed and sent themselves.
struct SentMessage: Identifiable {
    let id = UUID()
    let text: String
    let sentAt: Date = Date()
}

/// Everything shown in the chat, in the order it appeared.
enum ChatItem: Identifiable {
    case script(RevealedScriptStep)
    case sent(SentMessage)

    var id: UUID {
        switch self {
        case .script(let revealed): return revealed.id
        case .sent(let message): return message.id
        }
    }
}

extension Date {
    /// Short local time, e.g. "14:32" — shown under each message bubble.
    var messageTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: self)
    }
}
