/**
 * Audio Player Service
 *
 * Handles playback of ElevenLabs voice recommendations using AVFoundation.
 */

import Foundation
import AVFoundation
import Combine

@MainActor
class AudioPlayerService: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = AudioPlayerService()

    // MARK: - Published Properties

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackProgress: Double = 0

    // MARK: - Private Properties

    private var player: AVAudioPlayer?
    private var timer: Timer?

    // MARK: - Initialization

    private override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Playback Control

    /// Play audio from data
    func play(audioData: Data) {
        do {
            // Stop current playback
            stop()

            // Create player
            player = try AVAudioPlayer(data: audioData)
            player?.delegate = self
            player?.prepareToPlay()

            // Update duration
            duration = player?.duration ?? 0

            // Start playback
            player?.play()
            isPlaying = true

            // Start timer for progress updates
            startTimer()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }

    /// Play audio from URL
    func play(url: URL) {
        Task {
            do {
                // Download audio
                let (data, _) = try await URLSession.shared.data(from: url)

                await MainActor.run {
                    self.play(audioData: data)
                }
            } catch {
                print("Failed to download audio: \(error)")
            }
        }
    }

    /// Pause playback
    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    /// Resume playback
    func resume() {
        player?.play()
        isPlaying = true
        startTimer()
    }

    /// Stop playback
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        playbackProgress = 0
        stopTimer()
    }

    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    /// Seek to time
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        updateProgress()
    }

    // MARK: - Timer Management

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateProgress()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateProgress() {
        guard let player = player else { return }
        currentTime = player.currentTime
        if duration > 0 {
            playbackProgress = currentTime / duration
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stop()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("Audio decode error: \(error?.localizedDescription ?? "unknown")")
            self.stop()
        }
    }
}
