import SwiftUI

/// Photo bubble for .image script steps — a bundled image from Assets.xcassets,
/// fixed to 80% of screen width like the voice bubble (consistent regardless of
/// the source image's own resolution), with an optional caption and the same
/// bottom-right sent-time label as the other bubble types.
struct ImageMessageBubble: View {
    let imageName: String
    let caption: String?
    let isFromContact: Bool
    let sentAt: Date
    /// Called when the photo itself is tapped, to show it full-screen.
    var onTap: (() -> Void)? = nil

    private var bubbleWidth: CGFloat { UIScreen.main.bounds.width * 0.8 }

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
        VStack(alignment: .trailing, spacing: 4) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: bubbleWidth - 8)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
                .onTapGesture { onTap?() }

            if let caption {
                Text(caption)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            Text(sentAt.messageTimeString)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.trailing, 4)
        }
        .padding(4)
        .frame(width: bubbleWidth)
        .background(isFromContact ? Color.white : Color(red: 0.86, green: 0.98, blue: 0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
