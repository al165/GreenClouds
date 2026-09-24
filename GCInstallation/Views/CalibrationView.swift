import SwiftUI
import CoreMotion

/// Throwaway debug screen for tuning MotionManager's thresholds on real hardware.
/// Not part of the show — swap this in as the root view temporarily (see README)
/// to watch live gravity values while picking the phone up and setting it down,
/// then plug the numbers you observe back into MotionManager's thresholds.
struct CalibrationView: View {
    @StateObject private var reader = GravityReader()

    var body: some View {
        VStack(spacing: 24) {
            Text(reader.state == .pickedUp ? "PICKED UP" : "FLAT")
                .font(.largeTitle.bold())
                .foregroundColor(reader.state == .pickedUp ? .green : .red)

            VStack(alignment: .leading, spacing: 8) {
                Text("gravity.x: \(reader.x, specifier: "%.3f")")
                Text("gravity.y: \(reader.y, specifier: "%.3f")")
                Text("gravity.z: \(reader.z, specifier: "%.3f")")
                Text("|gravity.z|: \(abs(reader.z), specifier: "%.3f")")
                    .bold()
            }
            .font(.system(.body, design: .monospaced))

            Text("Watch |gravity.z|: near 1.0 flat, drops toward 0 when upright.\nUse the values here to set pickedUpThreshold / flatThreshold in MotionManager.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
        }
        .onAppear { reader.start() }
        .onDisappear { reader.stop() }
    }
}

private final class GravityReader: ObservableObject {
    @Published var x: Double = 0
    @Published var y: Double = 0
    @Published var z: Double = 1
    @Published var state: MotionManager.PhoneState = .flat

    private let motionManager = CMMotionManager()

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.x = motion.gravity.x
            self.y = motion.gravity.y
            self.z = motion.gravity.z
            self.state = abs(motion.gravity.z) < 1 - 0.7 && motion.gravity.y >= 0.7 ? .flat : .pickedUp
            // self.state = abs(motion.gravity.z) <= 0.7 ? .pickedUp : .flat
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}
