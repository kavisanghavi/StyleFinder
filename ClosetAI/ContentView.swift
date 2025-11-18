//
//  ContentView.swift
//  ClosetAI
//
//  Premium iOS design with modern typography and beautiful layout
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
                    Label("Closet", systemImage: "tshirt.fill")
                }
                .tag(1)

            OutfitGeneratorView()
                .tabItem {
                    Label("Style", systemImage: "sparkles")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(3)
        }
        .tint(Color(hex: "6366F1"))
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Scan Item")
                            .font(.system(size: 34, weight: .bold))

                        Text("Upload a photo to analyze with AI")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Image Section
                    if let image = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .padding(.horizontal, 20)

                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedImage = nil
                                    analysisResult = nil
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(28)
                        }
                    } else {
                        Button(action: { showingImagePicker = true }) {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(Color(hex: "6366F1"))

                                Text("Select Photo")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("Choose a clothing item from your library")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 320)
                            .background(Color(hex: "F5F5F7"))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [8]))
                            )
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                    }

                    // Analyze Button
                    if selectedImage != nil && analysisResult == nil {
                        Button(action: analyzeImage) {
                            HStack(spacing: 8) {
                                if isAnalyzing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(isAnalyzing ? "Analyzing..." : "Analyze with AI")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "6366F1"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isAnalyzing)
                        .padding(.horizontal, 20)
                    }

                    // Results
                    if let result = analysisResult {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "10B981"))
                                Text("Analysis Complete")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ResultRow(icon: "tag", label: "Type", value: result.type.capitalized)
                                Divider().padding(.leading, 56)
                                ResultRow(icon: "paintpalette", label: "Color", value: result.color.capitalized)
                                Divider().padding(.leading, 56)
                                ResultRow(icon: "square.grid.2x2", label: "Pattern", value: result.pattern.capitalized)
                                Divider().padding(.leading, 56)
                                ResultRow(icon: "star", label: "Style", value: result.style.capitalized)
                                Divider().padding(.leading, 56)
                                ResultRow(icon: "calendar", label: "Seasons", value: result.season.joined(separator: ", "))
                            }
                            .background(Color(hex: "F9FAFB"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)

                            if !result.pairs_well_with.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Pairs Well With")
                                        .font(.system(size: 17, weight: .semibold))
                                        .padding(.horizontal, 20)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(result.pairs_well_with, id: \.self) { item in
                                                Text(item.capitalized)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(Color(hex: "6366F1"))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color(hex: "6366F1").opacity(0.1))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }

                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedImage = nil
                                    analysisResult = nil
                                }
                            }) {
                                Text("Scan Another Item")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: "6366F1"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "6366F1").opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(hex: "FFFFFF"))
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
                    withAnimation(.spring(response: 0.4)) {
                        analysisResult = analysis
                        isAnalyzing = false
                    }
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

struct ResultRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "6366F1"))
                .frame(width: 24)

            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Wardrobe View

struct WardrobeView: View {
    @State private var items: [ClothingItem] = ClothingItem.samples

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        WardrobeCard(item: item)
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "F5F5F7"))
            .navigationTitle("My Closet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "6366F1"))
                    }
                }
            }
        }
    }
}

struct WardrobeCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: iconForType(item.type))
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(Color(hex: "6366F1"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Text(item.style)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }

    func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "shirt", "t-shirt", "blouse": return "tshirt"
        case "pants", "jeans": return "figure.walk"
        case "dress": return "figure.dress.line.vertical.figure"
        case "jacket", "coat": return "coat"
        case "shoes": return "shoe"
        default: return "tshirt"
        }
    }
}

// MARK: - Outfit Generator View

struct OutfitGeneratorView: View {
    @State private var occasion = "Work"
    @State private var isGenerating = false
    @State private var generatedOutfit: OutfitSuggestion?

    let occasions = ["Work", "Casual", "Date Night", "Gym", "Formal", "Party"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Outfit Generator")
                            .font(.system(size: 34, weight: .bold))

                        Text("AI-powered styling recommendations")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Occasion Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Occasion")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(occasions, id: \.self) { occ in
                                    Button(action: { occasion = occ }) {
                                        Text(occ)
                                            .font(.system(size: 15, weight: occasion == occ ? .semibold : .regular))
                                            .foregroundColor(occasion == occ ? .white : Color(hex: "6366F1"))
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(occasion == occ ? Color(hex: "6366F1") : Color(hex: "6366F1").opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Generate Button
                    Button(action: generateOutfit) {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isGenerating ? "Generating..." : "Generate Outfit")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "6366F1"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal, 20)

                    // Results
                    if let outfit = generatedOutfit {
                        VStack(alignment: .leading, spacing: 24) {
                            // Items
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Outfit")
                                    .font(.system(size: 20, weight: .semibold))
                                    .padding(.horizontal, 20)

                                VStack(spacing: 8) {
                                    ForEach(outfit.items, id: \.id) { item in
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(Color(hex: "6366F1").opacity(0.1))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Text(item.type.prefix(1).uppercased())
                                                        .font(.system(size: 17, weight: .semibold))
                                                        .foregroundColor(Color(hex: "6366F1"))
                                                )

                                            Text(item.type.capitalized)
                                                .font(.system(size: 15, weight: .medium))

                                            Spacer()
                                        }
                                        .padding(16)
                                        .background(Color(hex: "F9FAFB"))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // Reasoning
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "6366F1"))
                                    Text("Why This Works")
                                        .font(.system(size: 17, weight: .semibold))
                                }

                                Text(outfit.reasoning)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "F9FAFB"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)

                            // Style Tips
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "6366F1"))
                                    Text("Style Tips")
                                        .font(.system(size: 17, weight: .semibold))
                                }

                                Text(outfit.styleTips)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "F9FAFB"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)

                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    generatedOutfit = nil
                                }
                            }) {
                                Text("Generate Another")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: "6366F1"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "6366F1").opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(hex: "FFFFFF"))
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
                    withAnimation(.spring(response: 0.4)) {
                        generatedOutfit = outfit
                        isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var enableCloudBackup = false
    @State private var enableVoice = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "6366F1"))
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Closet Scanner")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Version 1.0.0")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Features") {
                    Toggle(isOn: $enableCloudBackup) {
                        Label {
                            Text("Cloud Backup")
                                .font(.system(size: 17))
                        } icon: {
                            Image(systemName: "cloud")
                                .foregroundColor(Color(hex: "6366F1"))
                        }
                    }

                    Toggle(isOn: $enableVoice) {
                        Label {
                            Text("Voice Recommendations")
                                .font(.system(size: 17))
                        } icon: {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(Color(hex: "6366F1"))
                        }
                    }
                }

                Section("Security") {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(Color(hex: "10B981"))
                        Text("AES-256 Encryption")
                            .font(.system(size: 17))
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "10B981"))
                    }

                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text("Keychain Storage")
                            .font(.system(size: 17))
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                }

                Section("Powered By") {
                    Label("Claude AI", systemImage: "brain.head.profile")
                    Label("ElevenLabs", systemImage: "waveform")
                    Label("Google Gemini", systemImage: "sparkles")
                    Label("Tigris Storage", systemImage: "cloud")
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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
