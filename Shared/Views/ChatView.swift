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
    /// Called after any message (typed or voice) has been appended as a sent bubble
    /// (i.e. `onBeforeSend` didn't intercept it) — for side effects that must happen
    /// only once the bubble is actually in the timeline, like GC Performance starting
    /// the sequence on the first send (so the scripted reply appears after it, not
    /// before). Receives the message that was just appended.
    var onDidSend: ((SentMessage) -> Void)? = nil

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
                ChatHeaderView(isFinished: sequencer.isFinished, avatarImageName: "Avatar")

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            if !timeline.isEmpty || sequencer.preparingStep != nil {
                                DateChip(text: "Today")
                            }
                            ForEach(timeline) { item in
                                row(for: item)
                                    .id(item.id)
                            }
                            if let preparingStep = sequencer.preparingStep {
                                StatusBubble(kind: preparingStep.kind, isFromContact: preparingStep.isFromContact)
                                    .id("statusBubble")
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                    }
                    .onChange(of: timeline.count) { _ in
                        guard let lastID = timeline.last?.id else { return }
                        withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                    }
                    .onChange(of: sequencer.preparingStep?.id) { newValue in
                        guard newValue != nil else { return }
                        withAnimation { proxy.scrollTo("statusBubble", anchor: .bottom) }
                    }
                }

                ComposeBar(text: $composeText, isFocused: $isComposeFocused, onSend: sendMessage, onSendVoice: sendVoiceMessage)
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
                    id: revealed.id,
                    isFromContact: revealed.step.isFromContact,
                    isPlaying: isLive ? !sequencer.isPaused : (isReplaying && !sequencer.isReplayPaused),
                    currentTime: isLive ? sequencer.currentTime : (isReplaying ? sequencer.replayCurrentTime : revealed.duration),
                    duration: revealed.duration,
                    sentAt: revealed.sentAt,
                    onToggle: isLive ? sequencer.togglePlayPause : { sequencer.toggleReplay(for: revealed.step) },
                    onSkipToEnd: isLive ? sequencer.skipToEnd : nil,
                    onSeek: isLive
                        ? { sequencer.seek(to: $0) }
                        : { sequencer.seekReplay(for: revealed.step, to: $0) }
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
            switch message.content {
            case .text(let text):
                MessageBubble(text: text, isFromContact: false, sentAt: message.sentAt)
            case .voice(let url, let duration):
                let isReplaying = sequencer.replayingStepID == message.id
                VoiceMessageBubble(
                    id: message.id,
                    isFromContact: false,
                    isPlaying: isReplaying && !sequencer.isReplayPaused,
                    currentTime: isReplaying ? sequencer.replayCurrentTime : duration,
                    duration: duration,
                    sentAt: message.sentAt,
                    onToggle: { sequencer.toggleReplay(id: message.id, url: url) },
                    onSkipToEnd: nil,
                    onSeek: { sequencer.seekReplay(id: message.id, url: url, to: $0) }
                )
            }
        }
    }

    private func sendMessage() {
        let trimmed = composeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        composeText = ""
        isComposeFocused = false

        if onBeforeSend?(trimmed) == true { return }

        let message = SentMessage(content: .text(trimmed))
        timeline.append(.sent(message))
        SoundEffectPlayer.shared.play(.messageSent)
        onDidSend?(message)
    }

    private func sendVoiceMessage(url: URL, duration: TimeInterval) {
        let message = SentMessage(content: .voice(url: url, duration: duration))
        timeline.append(.sent(message))
        SoundEffectPlayer.shared.play(.messageSent)
        onDidSend?(message)
    }
}

/// Small centered date divider above the messages, like WhatsApp's "Today" chip.
private struct DateChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
    }
}
