import SwiftUI

/// Top-level screen switcher: lock screen <-> chat. Owns the shared motion sensor
/// and playback sequencer since both screens react to them, and is the only place
/// that knows how to navigate between the two.
struct RootView: View {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var sequencer = PlaybackSequencer()

    @State private var isUnlocked = false
    @State private var showNotification = false
    @State private var timeline: [ChatItem] = []
    @State private var pendingResetWorkItem: DispatchWorkItem?
    @State private var pendingNotificationWorkItem: DispatchWorkItem?

    /// How long the phone must stay flat before everything resets back to the lock
    /// screen — a brief put-down (e.g. adjusting grip) shouldn't restart the piece.
    private let putDownResetDelay: TimeInterval = 15
    /// Delay after pickup before the notification "arrives" on the lock screen.
    private let notificationDelay: TimeInterval = 0.8

    var body: some View {
        ZStack {
            if isUnlocked {
                ChatView(sequencer: sequencer, timeline: $timeline)
                    .transition(.move(edge: .trailing))
            } else {
                LockScreenView(showNotification: showNotification, onNotificationTap: unlock)
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
                SoundEffectPlayer.shared.play(.messageReceived)
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
        let workItem = DispatchWorkItem {
            sequencer.reset()
            showNotification = false
            isUnlocked = false
            timeline = []
        }
        pendingResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + putDownResetDelay, execute: workItem)
    }

    private func unlock() {
        guard showNotification, !isUnlocked else { return }
        sequencer.start()
        withAnimation { isUnlocked = true }
    }
}
