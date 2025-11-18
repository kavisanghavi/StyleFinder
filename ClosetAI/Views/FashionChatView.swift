/**
 * Fashion Chat View
 *
 * Conversational AI chat for fashion advice using voice input/output
 */

import SwiftUI
import AVFoundation

struct FashionChatView: View {
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @StateObject private var chatVM = FashionChatViewModel()

    var body: some View {
        ZStack {
            Color(hex: "F8F9FA").ignoresSafeArea()

            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(chatVM.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if chatVM.isThinking {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "6366F1")))
                                    Text("AI is thinking...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(20)
                    }
                    .onChange(of: chatVM.messages.count) { _, _ in
                        if let lastMessage = chatVM.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Voice input button
                VStack(spacing: 12) {
                    if !chatVM.isRecording {
                        Button(action: { chatVM.startRecording() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20))
                                Text("Tap to Speak")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 12, x: 0, y: 4)
                        }
                    } else {
                        Button(action: { chatVM.stopRecording() }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red.opacity(0.3), lineWidth: 8)
                                            .scaleEffect(chatVM.isPulsing ? 1.3 : 1.0)
                                    )

                                Text("Recording... Tap to Send")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
            }
        }
        .navigationTitle("Fashion AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if !message.isUser {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "6366F1"))
                    }

                    Text(message.isUser ? "You" : "Fashion AI")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(message.isUser ? Color(hex: "EC4899") : Color(hex: "6366F1"))
                }

                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        message.isUser ?
                            LinearGradient(
                                colors: [Color(hex: "EC4899").opacity(0.1), Color(hex: "8B5CF6").opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color(hex: "6366F1").opacity(0.1), Color(hex: "8B5CF6").opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let audioUrl = message.audioUrl {
                    AudioPlaybackButton(audioUrl: audioUrl)
                }
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
    }
}

// MARK: - Audio Playback Button

struct AudioPlaybackButton: View {
    let audioUrl: String
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        Button(action: togglePlay) {
            HStack(spacing: 8) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 20))
                Text(isPlaying ? "Pause" : "Play Audio")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(Color(hex: "6366F1"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "6366F1").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func togglePlay() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            playAudio()
        }
    }

    func playAudio() {
        Task {
            guard let url = URL(string: audioUrl) else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    do {
                        audioPlayer = try AVAudioPlayer(data: data)
                        audioPlayer?.play()
                        isPlaying = true
                    } catch {
                        print("❌ Failed to play audio: \(error)")
                    }
                }
            } catch {
                print("❌ Failed to download audio: \(error)")
            }
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let audioUrl: String?
    let timestamp: Date

    init(text: String, isUser: Bool, audioUrl: String? = nil) {
        self.text = text
        self.isUser = isUser
        self.audioUrl = audioUrl
        self.timestamp = Date()
    }
}

// MARK: - Chat ViewModel

@MainActor
class FashionChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isRecording = false
    @Published var isThinking = false
    @Published var isPulsing = false

    private var audioRecorder: AVAudioRecorder?
    private let elevenLabsApiKey = "sk_1f24853eb5bd1e3f2c491bda23fd60a8a7767b5adde36a6e"

    init() {
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default)
        try? audioSession.setActive(true)

        // Add welcome message
        messages.append(ChatMessage(
            text: "Hi! I'm your AI fashion assistant. Ask me anything about your style, outfits, or fashion advice!",
            isUser: false
        ))
    }

    func startRecording() {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            isPulsing = true

            // Pulse animation
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                isPulsing = true
            }

            print("🎤 Recording started")
        } catch {
            print("❌ Failed to start recording: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        isPulsing = false

        guard let audioUrl = audioRecorder?.url else { return }

        print("🎤 Recording stopped, processing...")

        // Send to backend for transcription and AI response
        Task {
            await processVoiceInput(audioUrl: audioUrl)
        }
    }

    private func processVoiceInput(audioUrl: URL) async {
        do {
            // Read audio data
            let audioData = try Data(contentsOf: audioUrl)

            // Send to backend for processing (speech-to-text + Claude response + text-to-speech)
            isThinking = true

            let response = try await sendVoiceMessage(audioData: audioData)

            // Add user message (transcription)
            messages.append(ChatMessage(text: response.userText, isUser: true))

            // Add AI response with audio
            messages.append(ChatMessage(
                text: response.aiText,
                isUser: false,
                audioUrl: response.audioUrl
            ))

            // Auto-play AI response
            if let audioUrl = response.audioUrl, let url = URL(string: audioUrl) {
                playAudio(from: url)
            }

            isThinking = false
        } catch {
            print("❌ Failed to process voice input: \(error)")
            isThinking = false
        }
    }

    private func sendVoiceMessage(audioData: Data) async throws -> (userText: String, aiText: String, audioUrl: String?) {
        // For now, use a mock response
        // TODO: Implement actual backend endpoint for voice chat
        try await Task.sleep(nanoseconds: 1_000_000_000)

        return (
            userText: "What should I wear today?",
            aiText: "Based on your closet, I'd suggest pairing your blue shirt with those dark jeans. It's a classic, versatile look that works for most occasions!",
            audioUrl: nil
        )
    }

    private func playAudio(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    do {
                        let player = try AVAudioPlayer(data: data)
                        player.play()
                    } catch {
                        print("❌ Failed to play audio: \(error)")
                    }
                }
            } catch {
                print("❌ Failed to download audio: \(error)")
            }
        }
    }
}

#Preview {
    FashionChatView()
        .environmentObject(WardrobeViewModel())
}
