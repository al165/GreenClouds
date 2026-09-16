import SwiftUI

/// Full-screen photo viewer shown when tapping an image message bubble: the photo
/// fills the available space, the caption (if any) sits below it, and a back button
/// in the top-left returns to the chat.
struct FullScreenImageView: View {
    let imageName: String
    let caption: String?
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let caption {
                    Text(caption)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .padding(.top, 60)

            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 12)
        }
    }
}
