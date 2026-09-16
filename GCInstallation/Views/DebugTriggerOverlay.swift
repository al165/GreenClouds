#if targetEnvironment(simulator)
import SwiftUI

/// Simulator-only stand-in for MotionManager's accelerometer-based pickup/put-down
/// detection. The simulator has no accelerometer, so this exposes two buttons that
/// drive the same events directly. Not compiled into device builds — MotionManager
/// alone drives the real installation.
struct DebugTriggerOverlay: View {
    let onPickUp: () -> Void
    let onPutDown: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Button("Pick Up", action: onPickUp)
                Button("Put Down", action: onPutDown)
            }
            .font(.footnote.bold())
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 8)
        }
        .opacity(0.6)
    }
}
#endif
