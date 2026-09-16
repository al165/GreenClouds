import SwiftUI

/// WhatsApp-style voice note bubble: tappable play/pause, waveform that fills to show
/// progress, and a duration label. Any revealed voice bubble can be tapped — the live
/// (in-sequence) step plays/pauses normally, and an already-completed one can be
/// replayed from the start, independent of the sequence's own progression.
struct VoiceMessageBubble: View {
    let id: UUID
    let isFromContact: Bool
    /// True while this bubble's audio is actually producing sound right now (live or replay).
    let isPlaying: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    let sentAt: Date
    let onToggle: (() -> Void)?
    /// Dev-only: long-pressing the waveform skips to the end of the message.
    /// Only wired up for the live, in-sequence step.
    let onSkipToEnd: (() -> Void)?

    private var progress: Double {
        guard duration > 0 else { return isPlaying ? 0 : 1 }
        return min(max(currentTime / duration, 0), 1)
    }

    private var showsPlayIcon: Bool {
        !isPlaying
    }

    var body: some View {
        HStack {
            if isFromContact {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 10) {
                Button(action: { onToggle?() }) {
                    Circle()
                        .fill(isPlaying ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: showsPlayIcon ? "play.fill" : "pause.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        )
                }
                .buttonStyle(.plain)
                .disabled(onToggle == nil)

                WaveformView(id: id, progress: progress)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.6) { onSkipToEnd?() }

                Text(timeLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .frame(width: 34, alignment: .leading)
            }

            Text(sentAt.messageTimeString)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .background(isFromContact ? Color.white : Color(red: 0.86, green: 0.98, blue: 0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var timeLabel: String {
        let seconds = max(0, Int(currentTime.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct WaveformView: View {
    /// Seeds the per-message random waveform — each voice message gets its own
    /// shape, stable across re-renders, rather than every bubble looking identical.
    let id: UUID
    /// 0...1 — bars up to this fraction render as "played".
    let progress: Double

    private static let barCount = 40
    private static let barWidth: CGFloat = 2

    /// A clamped random walk seeded per-message rather than a shared/hand-picked
    /// sequence — avoids both the artificial "triangle wave" look a repeating
    /// pattern gives and every message showing the same waveform. The floor is
    /// kept fairly high so there are no long low/flat "silence" stretches.
    private var barHeights: [CGFloat] {
        var generator = SeededGenerator(seed: UInt64(bitPattern: Int64(id.hashValue)))
        var heights: [CGFloat] = []
        var current: CGFloat = 16
        for _ in 0..<Self.barCount {
            current = min(max(current + CGFloat.random(in: -6...6, using: &generator), 11), 24)
            heights.append(current)
        }
        return heights
    }

    var body: some View {
        GeometryReader { geometry in
            let heights = barHeights
            let spacing = max((geometry.size.width - CGFloat(heights.count) * Self.barWidth) / CGFloat(heights.count - 1), 1)
            HStack(spacing: spacing) {
                ForEach(0..<heights.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(barColor(for: index, count: heights.count))
                        .frame(width: Self.barWidth, height: heights[index])
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func barColor(for index: Int, count: Int) -> Color {
        let barPosition = Double(index) / Double(count)
        return barPosition <= progress ? Color.green : Color.gray.opacity(0.5)
    }
}

/// Deterministic RNG (xorshift64) so a given message id always produces the same
/// waveform, instead of a new random shape on every SwiftUI re-render.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xdeadbeef : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
