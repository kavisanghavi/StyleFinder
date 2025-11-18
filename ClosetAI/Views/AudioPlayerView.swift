/**
 * Audio Player View
 *
 * Beautiful audio player for ElevenLabs voice recommendations.
 */

import SwiftUI

struct AudioPlayerView: View {
    let audioURL: String?
    @StateObject private var player = AudioPlayerService.shared
    @State private var isExpanded = false

    var body: some View {
        if let urlString = audioURL, let url = URL(string: urlString) {
            VStack(spacing: 0) {
                // Compact player button
                if !isExpanded {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded = true
                        }
                        if !player.isPlaying {
                            player.play(url: url)
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Waveform animation
                            HStack(spacing: 3) {
                                ForEach(0..<4) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                        .frame(width: 3)
                                        .frame(height: player.isPlaying ? CGFloat.random(in: 12...24) : 12)
                                        .animation(
                                            player.isPlaying ?
                                            Animation.easeInOut(duration: 0.5).repeatForever() : .default,
                                            value: player.isPlaying
                                        )
                                }
                            }
                            .frame(width: 20, height: 24)

                            Text("Listen to Voice Recommendation")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }

                // Expanded player
                if isExpanded {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 16))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("Voice Recommendation")
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    isExpanded = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }

                        // Waveform visualization
                        HStack(spacing: 4) {
                            ForEach(0..<20) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        player.playbackProgress > Double(i) / 20 ?
                                        LinearGradient(
                                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        ) :
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(height: CGFloat.random(in: 20...50))
                            }
                        }
                        .frame(height: 60)

                        // Progress bar
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 4)

                                    // Progress
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * player.playbackProgress, height: 4)
                                }
                            }
                            .frame(height: 4)

                            // Time labels
                            HStack {
                                Text(formatTime(player.currentTime))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(formatTime(player.duration))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Controls
                        HStack(spacing: 32) {
                            // Rewind 15s
                            Button(action: {
                                player.seek(to: max(0, player.currentTime - 15))
                            }) {
                                Image(systemName: "gobackward.15")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primary)
                            }

                            // Play/Pause
                            Button(action: {
                                if player.isPlaying {
                                    player.pause()
                                } else {
                                    player.play(url: url)
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                        .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 12, x: 0, y: 4)

                                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }

                            // Forward 15s
                            Button(action: {
                                player.seek(to: min(player.duration, player.currentTime + 15))
                            }) {
                                Image(systemName: "goforward.15")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
                }
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    AudioPlayerView(audioURL: "https://example.com/audio.mp3")
        .padding()
}
