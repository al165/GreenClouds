import SwiftUI

/// The chat screen itself — shared by every app in this project. A caller (GC
/// Installation's RootView, GC Performance's own root) owns the sequencer/timeline
/// and decides how/when the chat is shown; this view has no opinion on that.
struct ChatView: View {
    @ObservedObject var sequencer: PlaybackSequencer
    @Binding var timeline: [ChatItem]
    /// Called before a typed message is handled, with the trimmed text. Return true
    /// to indicate it's been fully handled (e.g. a command like "reset") so the
    /// default "append as a sent bubble" behavior is skipped. Nil (the default)
    /// means every send just appends a bubble, as in GC Installation.
    var onBeforeSend: ((String) -> Bool)? = nil
    /// Called after a message has been appended as a sent bubble (i.e. `onBeforeSend`
    /// didn't intercept it) — for side effects that must happen only once the bubble
    /// is actually in the timeline, like GC Performance starting the sequence on the
    /// first send (so the scripted reply appears after it, not before).
    var onDidSend: ((String) -> Void)? = nil

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
                ChatHeaderView(activityText: sequencer.preparingStep?.kind.activityText, isFinished: sequencer.isFinished, avatarImageName: "Avatar")
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
        composeText = ""
        isComposeFocused = false

        if onBeforeSend?(trimmed) == true { return }

        timeline.append(.sent(SentMessage(text: trimmed)))
        SoundEffectPlayer.shared.play(.messageSent)
        onDidSend?(trimmed)
    }
}
