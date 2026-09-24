import Foundation
import CoreMotion

/// Detects whether the phone is lying flat (put down) or held upright (picked up),
/// using the device motion gravity vector with hysteresis and a debounce window so
/// brief jostling doesn't flip the state.
final class MotionManager: ObservableObject {
    enum PhoneState: Equatable {
        case flat
        case pickedUp
    }

    @Published private(set) var state: PhoneState = .flat

    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 30.0

    // |gravity.z| close to 1 means the phone is lying flat (screen up or down).
    // |gravity.z| close to 0 means the phone is upright/tilted.
    // The gap between these two thresholds is a dead zone that prevents flicker
    // right at the boundary — tune both while running the calibration harness
    // (see CalibrationView) on the actual phones used in the show.
    private let pickedUpThreshold = 0.7
    private let flatThreshold = 0.85
    private let requiredStableDuration: TimeInterval = 0.5

    private var candidateState: PhoneState?
    private var candidateSince: Date?

    func start() {
        #if targetEnvironment(simulator)
        // The simulator has no accelerometer — it reports constant, meaningless
        // gravity values that would otherwise fight VolumeButtonSimulator's
        // overrides. State is driven entirely via debugForceState(_:) there.
        return
        #else
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.process(gravityY: motion.gravity.y, gravityZ: motion.gravity.z)
        }
        #endif
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    #if targetEnvironment(simulator)
    /// Test-only: lets VolumeButtonSimulator drive `state` directly, bypassing
    /// the debounce that real accelerometer input needs.
    func debugForceState(_ newState: PhoneState) {
        candidateState = nil
        candidateSince = nil
        state = newState
    }
    #endif

    private func process(gravityY:Double, gravityZ: Double) {
        let magnitude = abs(gravityZ)

        // "flat" when its hanging upside down,
        // - |gravity.z| ~= 0
        // - gravity.y ~= 1

        let instantaneous: PhoneState?
        if ( magnitude < 1 - flatThreshold && gravityY >= flatThreshold ){
            instantaneous = .flat
        } else if ( magnitude >= 1 - pickedUpThreshold || gravityY < pickedUpThreshold ) {
             instantaneous = .pickedUp
        } else {
            instantaneous = nil // inside the dead zone; ignore this sample
        }

        // if magnitude <= pickedUpThreshold {
        //     instantaneous = .pickedUp
        // } else if magnitude >= flatThreshold {
        //     instantaneous = .flat

        guard let instantaneous else { return }

        guard instantaneous != state else {
            candidateState = nil
            candidateSince = nil
            return
        }

        if candidateState != instantaneous {
            candidateState = instantaneous
            candidateSince = Date()
            return
        }

        if let since = candidateSince, Date().timeIntervalSince(since) >= requiredStableDuration {
            state = instantaneous
            candidateState = nil
            candidateSince = nil
        }
    }
}
