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
                    SoundEffectPlayer.shared.play(.messageReceived)
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

    /// Starts the sequence right after the performer's first real message has been
    /// appended, so the scripted reply appears after it — with the normal "sending…"
    /// status first, same as every other step.
    private func handleDidSend(_ text: String) {
        guard !hasStarted else { return }
        hasStarted = true
        sequencer.start(skipFirstSendingPhase: false)
    }
}
