import SwiftUI

/// Bottom text input row, styled like WhatsApp's compose bar. Purely cosmetic beyond
/// sending — there's no history, editing, or attachments, just type and send.
struct ComposeBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("Message", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .focused(isFocused)
                .submitLabel(.send)
                .onSubmit(onSend)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(isEmpty ? .gray : Color(red: 0.11, green: 0.67, blue: 0.38))
            }
            .disabled(isEmpty)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
    }
}
