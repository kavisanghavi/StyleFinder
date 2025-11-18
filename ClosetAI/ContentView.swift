//
//  ContentView.swift
//  ClosetAI
//
//  Main app interface with tabs for different features
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Scan Tab
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(0)

            // Wardrobe Tab
            WardrobeView()
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt.fill")
                }
                .tag(1)

            // Outfit Generator Tab
            OutfitGeneratorView()
                .tabItem {
                    Label("Outfits", systemImage: "sparkles")
                }
                .tag(2)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

// MARK: - Scan View

struct ScanView: View {
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("AI Closet Scanner")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Scan your clothing items with AI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                Spacer()

                // Image Preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))

                        Text("No image selected")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: 300)
                }

                // Analysis Result
                if !analysisResult.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Analysis Results")
                                .font(.headline)

                            Text(analysisResult)
                                .font(.body)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Label("Select Photo", systemImage: "photo.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                    }

                    if selectedImage != nil {
                        Button(action: analyzeImage) {
                            HStack {
                                if isAnalyzing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Label("Analyze with AI", systemImage: "sparkles")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                        }
                        .disabled(isAnalyzing)
                    }
                }
                .padding()
            }
            .navigationTitle("Scan")
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
        analysisResult = ""

        Task {
            do {
                let analysis = try await APIClient.shared.analyzeClothing(imageData: imageData)

                await MainActor.run {
                    analysisResult = """
                    Type: \(analysis.type)
                    Color: \(analysis.color)
                    Pattern: \(analysis.pattern)
                    Style: \(analysis.style)
                    Seasons: \(analysis.season.joined(separator: ", "))
                    Pairs well with: \(analysis.pairs_well_with.joined(separator: ", "))
                    Confidence: \(Int(analysis.confidence * 100))%
                    """
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

// MARK: - Wardrobe View

struct WardrobeView: View {
    @State private var items: [ClothingItem] = ClothingItem.samples

    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { item in
                        WardrobeItemCard(item: item)
                    }
                }
                .padding()
            }
            .navigationTitle("My Wardrobe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}

struct WardrobeItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: iconForType(item.type))
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .lineLimit(1)

                Text(item.style)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(item.seasonEmojis)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
    @State private var generatedOutfit: String = ""

    let occasions = ["Work", "Casual", "Date Night", "Gym", "Formal Event", "Party"]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)

                    Text("Outfit Generator")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Let AI style your perfect outfit")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Occasion Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Occasion")
                        .font(.headline)
                        .padding(.leading)

                    Picker("Occasion", selection: $occasion) {
                        ForEach(occasions, id: \.self) { occasion in
                            Text(occasion).tag(occasion)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }

                // Generate Button
                Button(action: generateOutfit) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Label("Generate Outfit", systemImage: "wand.and.stars")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
                }
                .disabled(isGenerating)
                .padding(.horizontal)

                // Result
                if !generatedOutfit.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Outfit")
                                .font(.headline)

                            Text(generatedOutfit)
                                .font(.body)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                }

                Spacer()
            }
            .navigationTitle("Outfit Generator")
        }
    }

    func generateOutfit() {
        isGenerating = true
        generatedOutfit = ""

        Task {
            do {
                let items = ClothingItem.samples
                let outfit = try await APIClient.shared.generateOutfit(
                    wardrobeItems: items,
                    occasion: occasion
                )

                await MainActor.run {
                    var result = "📋 Items:\n"
                    for item in outfit.items {
                        result += "• \(item.type)\n"
                    }
                    result += "\n💭 Reasoning:\n\(outfit.reasoning)\n"
                    result += "\n✨ Style Tips:\n\(outfit.styleTips)"

                    generatedOutfit = result
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    generatedOutfit = "Error: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var enableCloudBackup = false
    @State private var enableVoiceRecommendations = true
    @State private var backendURL = "http://localhost:8000"
    @State private var showingURLEditor = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Features")) {
                    Toggle("Cloud Backup", isOn: $enableCloudBackup)
                    Toggle("Voice Recommendations", isOn: $enableVoiceRecommendations)
                }

                Section(header: Text("Backend Configuration")) {
                    HStack {
                        Text("Backend URL")
                        Spacer()
                        Button(action: { showingURLEditor = true }) {
                            Text(backendURL)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                    }
                }

                Section(header: Text("Privacy & Security")) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("AES-256-GCM Encryption")
                    }

                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        Text("Keychain Storage")
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Powered by")
                        Spacer()
                        Text("Claude, ElevenLabs, Gemini")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Backend URL", isPresented: $showingURLEditor) {
                TextField("URL", text: $backendURL)
                Button("Save", action: {})
                Button("Cancel", role: .cancel, action: {})
            }
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
