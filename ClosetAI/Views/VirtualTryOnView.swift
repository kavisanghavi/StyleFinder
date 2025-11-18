/**
 * Virtual Try-On View
 *
 * AI-powered virtual try-on using Nano Banana (Google Gemini)
 * Shows how clothing items would look on the user
 */

import SwiftUI

struct VirtualTryOnView: View {
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @EnvironmentObject var savedOutfitsManager: SavedOutfitsManager

    @State private var userPhoto: UIImage?
    @State private var selectedOutfit: SavedOutfit?
    @State private var outfitImages: [UIImage] = []
    @State private var resultImage: UIImage?
    @State private var positiveStatement: String?
    @State private var audioPlayer: AudioPlayerHelper?
    @State private var showingUserPicker = false
    @State private var showingOutfitPicker = false
    @State private var isGenerating = false
    @State private var errorMessage = ""
    @State private var showError = false

    let elevenLabsApiKey = "sk_1f24853eb5bd1e3f2c491bda23fd60a8a7767b5adde36a6e"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "EC4899"), Color(hex: "8B5CF6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Color(hex: "EC4899").opacity(0.3), radius: 20, x: 0, y: 10)

                            Image(systemName: "figure.stand.line.dotted.figure.stand")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.white)
                        }

                        Text("Virtual Try-On")
                            .font(.system(size: 28, weight: .bold))

                        Text("See how clothes look on you with AI")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Photo Selection Cards
                    HStack(spacing: 12) {
                        // User Photo
                        PhotoSelectionCard(
                            image: userPhoto,
                            title: "Your Photo",
                            icon: "person.fill",
                            color: "6366F1"
                        ) {
                            showingUserPicker = true
                        }

                        // Saved Outfit
                        SavedOutfitSelectionCard(
                            selectedOutfit: selectedOutfit,
                            outfitImages: outfitImages,
                            title: "Saved Outfit",
                            icon: "sparkles",
                            color: "EC4899"
                        ) {
                            showingOutfitPicker = true
                        }
                    }
                    .padding(.horizontal, 20)

                    // Generate Button
                    if userPhoto != nil && selectedOutfit != nil && resultImage == nil {
                        Button(action: generateTryOn) {
                            HStack(spacing: 12) {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.95)
                                } else {
                                    Image(systemName: "wand.and.stars.inverse")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                Text(isGenerating ? "Creating Magic..." : "Try It On")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "EC4899"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color(hex: "EC4899").opacity(0.4), radius: 20, x: 0, y: 10)
                        }
                        .disabled(isGenerating)
                        .padding(.horizontal, 20)
                    }

                    // Result
                    if let result = resultImage {
                        VStack(spacing: 20) {
                            // Success Header
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "10B981"))

                                Text("Here's How It Looks!")
                                    .font(.system(size: 24, weight: .bold))
                            }

                            // Result Image
                            Image(uiImage: result)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                                .padding(.horizontal, 20)

                            // Positive Statement from Claude
                            if let statement = positiveStatement {
                                HStack(spacing: 12) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "EC4899"))

                                    Text(statement)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                                .padding(.horizontal, 20)
                            }

                            // Action Buttons
                            HStack(spacing: 12) {
                                Button(action: resetTryOn) {
                                    Text("Try Another")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "6366F1"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(Color(hex: "6366F1").opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }

                                Button(action: {}) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 15))
                                        Text("Save")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color(hex: "EC4899"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Instructions (when no photos selected)
                    if userPhoto == nil || selectedOutfit == nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How It Works")
                                .font(.system(size: 20, weight: .semibold))

                            VStack(spacing: 12) {
                                InstructionRow(number: "1", text: "Upload a photo of yourself")
                                InstructionRow(number: "2", text: "Select a saved outfit to try on")
                                InstructionRow(number: "3", text: "Let AI show you how it looks!")
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(hex: "F8F9FA"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingUserPicker) {
                ImagePicker(image: $userPhoto, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingOutfitPicker) {
                SavedOutfitPickerSheet(
                    savedOutfitsManager: savedOutfitsManager,
                    wardrobeVM: wardrobeVM,
                    selectedOutfit: $selectedOutfit,
                    outfitImages: $outfitImages,
                    isPresented: $showingOutfitPicker
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    func generateTryOn() {
        guard let userImg = userPhoto,
              !outfitImages.isEmpty else {
            errorMessage = "Please select your photo and an outfit"
            showError = true
            return
        }

        isGenerating = true

        Task {
            do {
                let (image, statement, audioUrl) = try await APIClient.shared.virtualTryOn(
                    userImage: userImg,
                    clothingItems: outfitImages,
                    styleGuidance: selectedOutfit?.stylingTips
                )

                await MainActor.run {
                    withAnimation(.spring(response: 0.4)) {
                        resultImage = image
                        positiveStatement = statement
                        isGenerating = false
                    }
                }

                // Generate and play audio with ElevenLabs directly
                if let statement = statement, !statement.isEmpty {
                    do {
                        print("🔊 Generating audio with ElevenLabs...")
                        let voices = try await ElevenLabsTTS.shared.listVoices(apiKey: elevenLabsApiKey)
                        let voiceId = voices.first?.id ?? "pNInz6obpgDQGcFmaJgB"
                        print("🎤 Using voice: \(voiceId)")

                        let audioData = try await ElevenLabsTTS.shared.synthesize(
                            text: statement,
                            voiceId: voiceId,
                            apiKey: elevenLabsApiKey
                        )
                        print("✅ Audio generated (\(audioData.count) bytes), playing...")
                        await MainActor.run {
                            playAudio(data: audioData)
                        }
                    } catch {
                        print("❌ Failed to generate/play audio: \(error)")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Try-on failed: \(error.localizedDescription)"
                    showError = true
                    isGenerating = false
                }
            }
        }
    }

    func resetTryOn() {
        withAnimation(.spring(response: 0.3)) {
            resultImage = nil
            userPhoto = nil
            selectedOutfit = nil
            outfitImages = []
            positiveStatement = nil
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }

    func playAudio(data: Data) {
        do {
            audioPlayer = try AudioPlayerHelper(audioData: data)
            audioPlayer?.play()
            print("🔊 Playing positive statement audio")
        } catch {
            print("❌ Failed to play audio: \(error)")
        }
    }
}

// MARK: - Photo Selection Card

struct PhotoSelectionCard: View {
    let image: UIImage?
    let title: String
    let icon: String
    let color: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: color).opacity(0.1))
                            .frame(width: 140, height: 140)

                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color(hex: color))

                            Text("Tap to Add")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "EC4899"), Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Saved Outfit Selection Card

struct SavedOutfitSelectionCard: View {
    let selectedOutfit: SavedOutfit?
    let outfitImages: [UIImage]
    let title: String
    let icon: String
    let color: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let outfit = selectedOutfit, !outfitImages.isEmpty {
                    // Show preview of outfit items
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                            .frame(width: 140, height: 140)

                        // Show up to 4 clothing items in a grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                            ForEach(outfitImages.prefix(4), id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 65, height: 65)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                        .frame(width: 134, height: 134)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: color).opacity(0.1))
                            .frame(width: 140, height: 140)

                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color(hex: color))

                            Text("Tap to Select")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Text(selectedOutfit?.name ?? title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Saved Outfit Picker Sheet

struct SavedOutfitPickerSheet: View {
    let savedOutfitsManager: SavedOutfitsManager
    let wardrobeVM: WardrobeViewModel
    @Binding var selectedOutfit: SavedOutfit?
    @Binding var outfitImages: [UIImage]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F9FA").ignoresSafeArea()

                if savedOutfitsManager.savedOutfits.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 64, weight: .ultraLight))
                            .foregroundColor(.secondary)

                        Text("No Saved Outfits")
                            .font(.system(size: 24, weight: .bold))

                        Text("Create and save outfits in the Style tab to try them on")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(savedOutfitsManager.savedOutfits) { outfit in
                                SavedOutfitPickerCard(
                                    outfit: outfit,
                                    wardrobeVM: wardrobeVM
                                ) {
                                    selectOutfit(outfit)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Select Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
        }
    }

    func selectOutfit(_ outfit: SavedOutfit) {
        selectedOutfit = outfit

        // Load all clothing item images
        Task {
            let items = outfit.getItems(from: wardrobeVM.items)
            var images: [UIImage] = []

            for item in items {
                if let url = URL(string: item.imagePath) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let image = UIImage(data: data) {
                            images.append(image)
                        }
                    } catch {
                        print("Failed to load image: \(error)")
                    }
                }
            }

            await MainActor.run {
                outfitImages = images
                isPresented = false
            }
        }
    }
}

// MARK: - Saved Outfit Picker Card

struct SavedOutfitPickerCard: View {
    let outfit: SavedOutfit
    let wardrobeVM: WardrobeViewModel
    let action: () -> Void

    @State private var itemImages: [UIImage] = []

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Outfit preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .frame(height: 140)

                    if itemImages.isEmpty {
                        ProgressView()
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                            ForEach(itemImages.prefix(4), id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 65)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                        .padding(4)
                    }
                }

                // Outfit info
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.name)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)

                    Text(outfit.occasion)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .task {
            loadImages()
        }
    }

    func loadImages() {
        Task {
            let items = outfit.getItems(from: wardrobeVM.items)
            var images: [UIImage] = []

            for item in items {
                if let url = URL(string: item.imagePath) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let image = UIImage(data: data) {
                            images.append(image)
                        }
                    } catch {
                        print("Failed to load image: \(error)")
                    }
                }
            }

            await MainActor.run {
                itemImages = images
            }
        }
    }
}

// MARK: - Audio Player Helper

import AVFoundation

class AudioPlayerHelper {
    private var audioPlayer: AVAudioPlayer?

    init(audioData: Data) throws {
        audioPlayer = try AVAudioPlayer(data: audioData)
        audioPlayer?.prepareToPlay()
    }

    func play() {
        audioPlayer?.play()
    }

    func stop() {
        audioPlayer?.stop()
    }
}

#Preview {
    VirtualTryOnView()
        .environmentObject(WardrobeViewModel())
        .environmentObject(SavedOutfitsManager())
}
