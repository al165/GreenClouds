import SwiftUI

/// Fake iOS lock screen: clock widget, background image, and (once triggered) a
/// notification banner for the incoming voice message. Tapping the notification
/// is the only interactive element — everything else is static dressing.
struct LockScreenView: View {
    let showNotification: Bool
    var onNotificationTap: () -> Void

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Image("LockScreenBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 6) {
                Text(dateString)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6)
                Text(timeString)
                    .font(.system(size: 96, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6)

                if showNotification {
                    notificationBanner
                        .padding(.top, 28)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            .padding(.top, 90)
            .padding(.horizontal, 16)
        }
        .onReceive(timer) { now = $0 }
    }

    private var notificationBanner: some View {
        Button(action: onNotificationTap) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.0, green: 0.5, blue: 0.44))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "message.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("WhatsUp")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("now")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Text("New voice message received")
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: now)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: now)
    }
}
