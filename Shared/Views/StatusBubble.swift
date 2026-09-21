import SwiftUI

/// Transient status bubble shown in the chat itself while a script step is being
/// "sent" — mirrors WhatsApp's own typing-indicator bubble, rather than text in the
/// header. What it shows depends on the kind of step about to appear.
struct StatusBubble: View {
    let kind: ScriptStepKind
    let isFromContact: Bool

    var body: some View {
        HStack {
            if isFromContact {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
    }

    private var bubble: some View {
        content
            .frame(minWidth: 40, minHeight: 16)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isFromContact ? Color.white : Color(red: 0.86, green: 0.98, blue: 0.78))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .text:
            TypingDotsView()
        case .voice:
            PulsingIcon(systemName: "mic.fill")
        case .image:
            PulsingIcon(systemName: "photo.fill")
        }
    }
}

/// An SF Symbol that gently pulses (a slight scale and fade) while it's on screen.
private struct PulsingIcon: View {
    let systemName: String

    @State private var isPulsing = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16))
            .foregroundColor(.secondary)
            .scaleEffect(isPulsing ? 1.12 : 0.95)
            .opacity(isPulsing ? 1 : 0.55)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

/// Three dots that bounce in sequence, like WhatsApp/iMessage's typing indicator.
private struct TypingDotsView: View {
    @State private var isBouncing = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 7, height: 7)
                    .offset(y: isBouncing ? -3 : 3)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: isBouncing
                    )
            }
        }
        .onAppear { isBouncing = true }
    }
}
