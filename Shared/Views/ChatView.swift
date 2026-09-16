import SwiftUI

/// The chat screen, shown once the audience member taps the lock-screen notification.
/// No navigation back to the lock screen from here — that only happens when the phone
/// is put down, which RootView handles by resetting the sequencer/timeline and
/// unmounting this view (its own compose-bar state resets for free when that happens).
struct ChatView: View {
    @ObservedObject var sequencer: PlaybackSequencer
    @Binding var timeline: [ChatItem]

    @State private var composeText = ""
    @FocusState private var isComposeFocused: Bool
    @State private var fullScreenImage: (imageName: String, caption: String?)?

    //private let backgroundColor = Color(red: 0.9, green: 0.94, blue: 0.9)
    //private let backgroundColor = Color(red: 0.91, green: 0.88, blue: 0.83)
    private let backgroundColor = Color(red: 0.95, green: 0.92, blue: 0.87)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Set avatarImageName to an Assets.xcassets image name (same convention as
                // LockScreenBackground/photo_01) to show a photo instead of the placeholder icon.
                ChatHeaderView(activityText: sequencer.preparingStep?.kind.activityText, avatarImageName: "Avatar")
                    .ignoresSafeArea(edges: .top)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(timeline) { item in
                                row(for: item)
                                    .id(item.id)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                    }
                    .onChange(of: timeline.count) { _ in
                        guard let lastID = timeline.last?.id else { return }
                        withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                    }
                }

                ComposeBar(text: $composeText, isFocused: $isComposeFocused, onSend: sendMessage)
            }

            if let fullScreenImage {
                FullScreenImageView(
                    imageName: fullScreenImage.imageName,
                    caption: fullScreenImage.caption,
                    onBack: { withAnimation { self.fullScreenImage = nil } }
                )
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isComposeFocused = false }
    }

    @ViewBuilder
    private func row(for item: ChatItem) -> some View {
        switch item {
        case .script(let revealed):
            switch revealed.step.kind {
            case .voice:
                let isLive = sequencer.currentlyPlayingStepID == revealed.id
                let isReplaying = sequencer.replayingStepID == revealed.id
                VoiceMessageBubble(
                    step: revealed.step,
                    isPlaying: isLive ? !sequencer.isPaused : (isReplaying && !sequencer.isReplayPaused),
                    currentTime: isLive ? sequencer.currentTime : (isReplaying ? sequencer.replayCurrentTime : revealed.duration),
                    duration: revealed.duration,
                    sentAt: revealed.sentAt,
                    onToggle: isLive ? sequencer.togglePlayPause : { sequencer.toggleReplay(for: revealed.step) },
                    onSkipToEnd: isLive ? sequencer.skipToEnd : nil
                )
            case .text(let text):
                MessageBubble(text: text, isFromContact: revealed.step.isFromContact, sentAt: revealed.sentAt)
            case .image(let imageName, let caption):
                ImageMessageBubble(
                    imageName: imageName,
                    caption: caption,
                    isFromContact: revealed.step.isFromContact,
                    sentAt: revealed.sentAt,
                    onTap: { withAnimation { fullScreenImage = (imageName, caption) } }
                )
            }
        case .sent(let message):
            MessageBubble(text: message.text, isFromContact: false, sentAt: message.sentAt)
        }
    }

    private func sendMessage() {
        let trimmed = composeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        timeline.append(.sent(SentMessage(text: trimmed)))
        composeText = ""
        isComposeFocused = false
        SoundEffectPlayer.shared.play(.messageSent)
    }
}
