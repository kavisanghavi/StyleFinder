//
//  ContentView.swift
//  ClosetAI
//
//  Modern, polished UI with beautiful design
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(0)

            WardrobeView()
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt.fill")
                }
                .tag(1)

            OutfitGeneratorView()
                .tabItem {
                    Label("Outfits", systemImage: "sparkles")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.purple)
    }
}

// MARK: - Scan View

struct ScanView: View {
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: ClothingAnalysis?
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .purple.opacity(0.3), radius: 20, y: 10)

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 45))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 20)

                            Text("AI Closet Scanner")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))

                            Text("Powered by Claude AI")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Image Preview Card
                        VStack(spacing: 16) {
                            if let image = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 280)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

                                    // Remove button
                                    Button(action: { selectedImage = nil; analysisResult = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                    }
                                    .padding(12)
                                }
                                .padding(.horizontal)
                            } else {
                                Button(action: { showingImagePicker = true }) {
                                    VStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(height: 280)

                                            VStack(spacing: 12) {
                                                Image(systemName: "photo.on.rectangle.angled")
                                                    .font(.system(size: 60))
                                                    .foregroundStyle(LinearGradient(
                                                        colors: [.blue, .purple],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ))

                                                Text("Tap to select a photo")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)

                                                Text("Choose a clothing item to analyze")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }

                        // Analysis Results
                        if let result = analysisResult {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Analysis Complete")
                                        .font(.headline)
                                }
                                .padding(.horizontal)

                                VStack(spacing: 12) {
                                    AnalysisRow(icon: "tag.fill", label: "Type", value: result.type.capitalized, color: .blue)
                                    AnalysisRow(icon: "paintpalette.fill", label: "Color", value: result.color.capitalized, color: .orange)
                                    AnalysisRow(icon: "square.grid.2x2.fill", label: "Pattern", value: result.pattern.capitalized, color: .purple)
                                    AnalysisRow(icon: "star.fill", label: "Style", value: result.style.capitalized, color: .pink)
                                    AnalysisRow(icon: "calendar.circle.fill", label: "Seasons", value: result.season.joined(separator: ", "), color: .green)
                                    AnalysisRow(icon: "sparkles", label: "Confidence", value: "\(Int(result.confidence * 100))%", color: .yellow)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                                .padding(.horizontal)

                                if !result.pairs_well_with.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Pairs well with")
                                            .font(.headline)
                                            .padding(.horizontal)

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(result.pairs_well_with, id: \.self) { item in
                                                    Text(item.capitalized)
                                                        .font(.subheadline)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                        .background(LinearGradient(
                                                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ))
                                                        .cornerRadius(20)
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical)
                        }

                        // Action Buttons
                        if selectedImage != nil {
                            Button(action: analyzeImage) {
                                HStack(spacing: 12) {
                                    if isAnalyzing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.title3)
                                        Text("Analyze with AI")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                            }
                            .disabled(isAnalyzing || analysisResult != nil)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    func analyzeImage() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            showingError = true
            return
        }

        isAnalyzing = true

        Task {
            do {
                let analysis = try await APIClient.shared.analyzeClothing(imageData: imageData)
                await MainActor.run {
                    analysisResult = analysis
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to analyze: \(error.localizedDescription)"
                    showingError = true
                    isAnalyzing = false
                }
            }
        }
    }
}

struct AnalysisRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
}

// MARK: - Wardrobe View

struct WardrobeView: View {
    @State private var items: [ClothingItem] = ClothingItem.samples

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items) { item in
                            WardrobeItemCard(item: item)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Wardrobe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }
                }
            }
        }
    }
}

struct WardrobeItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image area
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: iconForType(item.type))
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }

            // Info section
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayName)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text(item.style)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)

                    Text(item.seasonEmojis)
                        .font(.caption)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "shirt", "t-shirt", "blouse": return "tshirt.fill"
        case "pants", "jeans": return "figure.walk"
        case "dress": return "figure.dress.line.vertical.figure"
        case "jacket", "coat": return "coat.fill"
        case "shoes": return "shoe.fill"
        default: return "tshirt.fill"
        }
    }
}

// MARK: - Outfit Generator View

struct OutfitGeneratorView: View {
    @State private var occasion = "Work"
    @State private var isGenerating = false
    @State private var generatedOutfit: OutfitSuggestion?

    let occasions = ["Work", "Casual", "Date Night", "Gym", "Formal Event", "Party"]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .purple.opacity(0.3), radius: 20, y: 10)

                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 45))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 20)

                            Text("Outfit Generator")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))

                            Text("AI-powered styling")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Occasion Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Occasion")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(occasions, id: \.self) { occ in
                                        OccasionButton(
                                            title: occ,
                                            isSelected: occasion == occ,
                                            action: { occasion = occ }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Generate Button
                        Button(action: generateOutfit) {
                            HStack(spacing: 12) {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .font(.title3)
                                    Text("Generate Outfit")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                        }
                        .disabled(isGenerating)
                        .padding(.horizontal)

                        // Results
                        if let outfit = generatedOutfit {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Your Perfect Outfit")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                // Items
                                VStack(spacing: 12) {
                                    ForEach(outfit.items, id: \.id) { item in
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(LinearGradient(
                                                    colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Text(item.type.prefix(1).uppercased())
                                                        .font(.title3)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.purple)
                                                )

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.type.capitalized)
                                                    .font(.headline)
                                                Text(item.reasoning)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)

                                // Reasoning
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Why this works", systemImage: "lightbulb.fill")
                                        .font(.headline)
                                        .foregroundColor(.purple)

                                    Text(outfit.reasoning)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)

                                // Style Tips
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Style Tips", systemImage: "star.fill")
                                        .font(.headline)
                                        .foregroundColor(.pink)

                                    Text(outfit.styleTips)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color.pink.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func generateOutfit() {
        isGenerating = true
        generatedOutfit = nil

        Task {
            do {
                let items = ClothingItem.samples
                let outfit = try await APIClient.shared.generateOutfit(
                    wardrobeItems: items,
                    occasion: occasion
                )

                await MainActor.run {
                    generatedOutfit = outfit
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                }
            }
        }
    }
}

struct OccasionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    isSelected ?
                    LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color(.systemGray5)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var enableCloudBackup = false
    @State private var enableVoiceRecommendations = true

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        Text("AI Closet Scanner")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)

                Section(header: Text("AI Features")) {
                    Toggle(isOn: $enableCloudBackup) {
                        Label("Cloud Backup", systemImage: "cloud.fill")
                    }
                    Toggle(isOn: $enableVoiceRecommendations) {
                        Label("Voice Recommendations", systemImage: "speaker.wave.2.fill")
                    }
                }

                Section(header: Text("Privacy & Security")) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("AES-256-GCM Encryption")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }

                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        Text("Keychain Storage")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Section(header: Text("Powered By")) {
                    Label("Claude (Anthropic)", systemImage: "brain.head.profile")
                    Label("ElevenLabs", systemImage: "waveform")
                    Label("Google Gemini", systemImage: "sparkles")
                    Label("Tigris Storage", systemImage: "cloud.fill")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
