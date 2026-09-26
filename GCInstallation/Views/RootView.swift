import SwiftUI

/// Top-level screen switcher: lock screen <-> chat. Owns the shared motion sensor
/// and playback sequencer since both screens react to them, and is the only place
/// that knows how to navigate between the two.
struct RootView: View {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var sequencer = PlaybackSequencer()
    @Environment(\.scenePhase) private var scenePhase

    @State private var isUnlocked = false
    @State private var showNotification = false
    @State private var timeline: [ChatItem] = []
    @State private var pendingResetWorkItem: DispatchWorkItem?
    @State private var pendingNotificationWorkItem: DispatchWorkItem?
    @State private var backgroundedAt: Date?

    /// How long the phone must stay flat before everything resets back to the lock
    /// screen — a brief put-down (e.g. adjusting grip) shouldn't restart the piece.
    private let putDownResetDelay: TimeInterval = 5
    /// Delay after pickup before the notification "arrives" on the lock screen.
    private let notificationDelay: TimeInterval = 1.2
    /// How long the app must have been in the background (e.g. screen turned off with
    /// the power button) before returning to it resets everything. The app is
    /// suspended while backgrounded, so this is checked on return rather than timed.
    private let backgroundResetDelay: TimeInterval = 15

    var body: some View {
        ZStack {
            if isUnlocked {
                ChatView(sequencer: sequencer, timeline: $timeline)
                    .transition(.move(edge: .trailing))
            } else {
                LockScreenView(showNotification: showNotification, onNotificationTap: unlock, avatarImageName: "Avatar")
                    .transition(.opacity)
            }
            #if targetEnvironment(simulator)
            DebugTriggerOverlay(
                onPickUp: { motionManager.debugForceState(.pickedUp) },
                onPutDown: { motionManager.debugForceState(.flat) }
            )
            #endif
        }
        .animation(.easeInOut(duration: 0.3), value: isUnlocked)
        .onAppear {
            // Registered once, up front — the first message of a sequence is
            // revealed synchronously inside sequencer.start(), before ChatView
            // would have had a chance to mount and register this itself.
            sequencer.onStepRevealed = { step, duration in
                timeline.append(.script(RevealedScriptStep(step: step, duration: duration)))
                // The lock-screen notification already played the alert for the
                // first message, so only later messages get the received sound.
                if step.id != Script.steps.first?.id {
                    SoundEffectPlayer.shared.play(.messageReceived)
                }
            }
            motionManager.start()
        }
        .onDisappear { motionManager.stop() }
        .onChange(of: motionManager.state) { newState in
            switch newState {
            case .pickedUp:
                pendingResetWorkItem?.cancel()
                pendingResetWorkItem = nil
                guard !isUnlocked, !showNotification else { return }
                scheduleNotification()
            case .flat:
                pendingNotificationWorkItem?.cancel()
                pendingNotificationWorkItem = nil
                scheduleReset()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                backgroundedAt = Date()
            case .active:
                guard let since = backgroundedAt else { return }
                backgroundedAt = nil
                guard Date().timeIntervalSince(since) >= backgroundResetDelay else { return }
                resetToLockScreen()
                // Motion state won't change if the phone is still being held, so
                // re-trigger the pickup flow as if it had just been picked up.
                if motionManager.state == .pickedUp {
                    scheduleNotification()
                }
            default:
                break
            }
        }
    }

    private func scheduleNotification() {
        let workItem = DispatchWorkItem {
            withAnimation { showNotification = true }
            SoundEffectPlayer.shared.play(.lockScreenAlert)
        }
        pendingNotificationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + notificationDelay, execute: workItem)
    }

    private func scheduleReset() {
        let workItem = DispatchWorkItem { resetToLockScreen() }
        pendingResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + putDownResetDelay, execute: workItem)
    }

    private func resetToLockScreen() {
        pendingResetWorkItem?.cancel()
        pendingResetWorkItem = nil
        pendingNotificationWorkItem?.cancel()
        pendingNotificationWorkItem = nil
        sequencer.reset()
        showNotification = false
        isUnlocked = false
        timeline = []
    }

    private func unlock() {
        guard showNotification, !isUnlocked else { return }
        sequencer.start()
        withAnimation { isUnlocked = true }
    }
}
