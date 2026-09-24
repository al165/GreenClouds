import SwiftUI

/// Static header bar styled like a WhatsApp conversation header.
/// Intentionally non-interactive — there is nothing behind the chevron/avatar to navigate to.
struct ChatHeaderView: View {
    /// True once the scripted sequence has fully played out — shows "offline" instead
    /// of "online" to signal the performance has ended.
    var isFinished: Bool = false
    /// Optional Assets.xcassets image name; falls back to a placeholder icon when nil.
    var avatarImageName: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))

            avatar

            VStack(alignment: .leading, spacing: 1) {
                Text("Green Clouds")
                    .font(.system(size: 17, weight: .light))
                Text(isFinished ? "offline" : "online")
                    .foregroundColor(.black.opacity(0.8))
                    .font(.caption2)
            }

            Spacer()

            Image(systemName: "phone.fill")
                .font(.system(size: 17))

            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .rotationEffect(.degrees(90))
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 10)
        // Only the background extends up behind the status bar; the header itself
        // stays inside the safe area so the VStack below it (the message list)
        // starts exactly at the header's bottom edge, with no dead strip between.
        .background(Color.white.ignoresSafeArea(edges: .top))
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarImageName {
            Image(avatarImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                )
        }
    }
}
