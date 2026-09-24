import SwiftUI
import UIKit

/// Plain text bubble, used for .text script steps and for messages the audience sends.
struct MessageBubble: View {
    let text: String
    let isFromContact: Bool
    let sentAt: Date

    private let font = UIFont.systemFont(ofSize: 16, weight: .light)
    private let timeFont = UIFont.systemFont(ofSize: 10, weight: .light)
    private let horizontalPadding: CGFloat = 12
    private let verticalPadding: CGFloat = 8

    var body: some View {
        bubble
            .frame(maxWidth: .infinity, alignment: isFromContact ? .leading : .trailing)
    }

    private var bubble: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(text)
                .font(Font(font))
                .multilineTextAlignment(.leading)
            Text(sentAt.messageTimeString)
                .font(Font(timeFont))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(width: bubbleWidth, alignment: .leading)
        .background(isFromContact ? Color.white : Color(red: 0.84, green: 0.99, blue: 0.82))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    /// Measures the message text (and the timestamp label) at their rendered
    /// fonts to find the narrowest width that fits, wrapping as needed, capped
    /// at 80% of the screen. A fixed width sidesteps SwiftUI's stack-flexibility
    /// heuristics, which don't reliably shrink a maxWidth-capped bubble to fit
    /// short text when it sits opposite a Spacer or inside a LazyVStack row.
    private var bubbleWidth: CGFloat {
        let maxContentWidth = UIScreen.main.bounds.width * 0.8 - horizontalPadding * 2
        let textWidth = measuredWidth(of: text, font: font, maxWidth: maxContentWidth)
        let timeWidth = measuredWidth(of: sentAt.messageTimeString, font: timeFont, maxWidth: maxContentWidth)
        return min(max(textWidth, timeWidth), maxContentWidth) + horizontalPadding * 2
    }

    private func measuredWidth(of string: String, font: UIFont, maxWidth: CGFloat) -> CGFloat {
        let constraint = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let bounds = (string as NSString).boundingRect(
            with: constraint,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(bounds.width)
    }
}
