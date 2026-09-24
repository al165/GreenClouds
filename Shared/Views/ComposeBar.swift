import SwiftUI

/// Bottom text input row, styled like WhatsApp's compose bar: type-and-send text, or
/// hold the mic button to record a voice message (release to send, drag left past
/// `cancelThreshold` to discard instead). No history or attachments beyond that.
struct ComposeBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onSendVoice: (URL, TimeInterval) -> Void

    @StateObject private var recorder = VoiceRecorder()
    @State private var dragTranslation: CGSize = .zero
    @State private var isCanceling = false

    private let cancelThreshold: CGFloat = -80
    private let accentColor = Color(red: 0.11, green: 0.67, blue: 0.38)
    private let buttonDiameter: CGFloat = 48

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if recorder.isRecording {
                    recordingIndicator
                } else {
                    TextField("Message", text: $text, axis: .vertical)
                        .font(.system(size: 17, weight: .light))
                        .lineLimit(1...4)
                        .focused(isFocused)
                        .submitLabel(.send)
                        .onSubmit(onSend)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

            actionButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var actionButton: some View {
        if isEmpty {
            Image(systemName: "mic.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: buttonDiameter, height: buttonDiameter)
                .background(Circle().fill(recorder.isRecording && isCanceling ? .red : accentColor))
                .offset(x: min(0, dragTranslation.width))
                .gesture(recordingGesture)
        } else {
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: buttonDiameter, height: buttonDiameter)
                    .background(Circle().fill(accentColor))
            }
            .buttonStyle(.plain)
        }
    }

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)

            Text(elapsedString)
                .font(.system(size: 15))
                .monospacedDigit()
                .foregroundColor(.secondary)

            Spacer()

            if isCanceling {
                Text("Release to cancel")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Slide to cancel")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var elapsedString: String {
        let seconds = max(0, Int(recorder.elapsed.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var recordingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !recorder.isRecording {
                    recorder.startRecording()
                }
                dragTranslation = value.translation
                isCanceling = value.translation.width < cancelThreshold
            }
            .onEnded { value in
                let canceled = value.translation.width < cancelThreshold
                dragTranslation = .zero
                isCanceling = false
                if canceled {
                    recorder.cancelRecording()
                } else if let result = recorder.finishRecording() {
                    onSendVoice(result.url, result.duration)
                }
            }
    }
}
