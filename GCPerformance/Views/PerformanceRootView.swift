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
        ChatView(sequencer: sequencer, timeline: $timeline, onBeforeSend: handleSend)
            .onAppear {
                sequencer.onStepRevealed = { step, duration in
                    timeline.append(.script(RevealedScriptStep(step: step, duration: duration)))
                    SoundEffectPlayer.shared.play(.messageReceived)
                }
            }
    }

    /// Returns true if the message was fully handled here (a command), so ChatView
    /// shouldn't also append it as a normal outgoing bubble.
    private func handleSend(_ text: String) -> Bool {
        guard text.caseInsensitiveCompare(resetCommand) != .orderedSame else {
            sequencer.reset()
            timeline = []
            hasStarted = false
            return true
        }

        if !hasStarted {
            hasStarted = true
            sequencer.start()
        }
        return false
    }
}
