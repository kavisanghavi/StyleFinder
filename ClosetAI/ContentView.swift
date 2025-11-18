//
//  ContentView.swift
//  ClosetAI
//
//  Premium iOS design with modern typography and beautiful layout
//

import SwiftUI

struct ContentView: View {
    @StateObject private var wardrobeVM = WardrobeViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WardrobeView()
                .tabItem {
                    Label("Closet", systemImage: "tshirt.fill")
                }
                .tag(0)

            OutfitGeneratorView()
                .tabItem {
                    Label("Style", systemImage: "sparkles")
                }
                .tag(1)

            VirtualTryOnView()
                .tabItem {
                    Label("Try-On", systemImage: "figure.stand.line.dotted.figure.stand")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .environmentObject(wardrobeVM)
        .tint(Color(hex: "6366F1"))
    }
}

// MARK: - Outfits Sheet (Popup)

struct OutfitsSheetView: View {
    let outfits: [OutfitSuggestion]
    let wardrobeItems: [ClothingItem]
    let savedOutfitsManager: SavedOutfitsManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F9FA").ignoresSafeArea()

                TabView {
                    ForEach(outfits) { outfit in
                        ScrollView {
                            OutfitCardView(
                                outfit: outfit,
                                wardrobeItems: wardrobeItems,
                                onSave: {
                                    savedOutfitsManager.saveOutfit(outfit, wardrobeItems: wardrobeItems)
                                }
                            )
                            .padding(20)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            .navigationTitle("Your Outfit Styles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Scanner Sheet View

struct ScannerSheetView: View {
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var showingCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Add to Closet")
                        .font(.system(size: 28, weight: .bold))

                    Text("AI will analyze in the background")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                Spacer()

                VStack(spacing: 16) {
                    // Camera Button
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button(action: { showingCamera = true }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "6366F1").opacity(0.1))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "6366F1"))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Take Photo")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Text("Instant AI analysis")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }

                    // Photo Library Button
                    Button(action: { showingImagePicker = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "8B5CF6").opacity(0.1))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose Photo")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("From your library")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color(hex: "F8F9FA"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: Binding(
                    get: { nil },
                    set: { if let image = $0 { handleImageSelected(image) } }
                ), sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: Binding(
                    get: { nil },
                    set: { if let image = $0 { handleImageSelected(image) } }
                ), sourceType: .camera)
            }
        }
    }

    func handleImageSelected(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to process image")
            return
        }

        // Create placeholder item immediately
        let placeholderId = UUID()
        let placeholder = ClothingItem(
            id: placeholderId,
            imagePath: "",
            type: "Analyzing...",
            color: "",
            pattern: "",
            style: "",
            season: [],
            pairsWellWith: [],
            confidence: 0.0,
            isProcessing: true
        )

        // Add placeholder to closet immediately
        wardrobeVM.addItem(placeholder, imageData: nil)

        // Close the sheet immediately
        dismiss()

        // Process in background
        Task {
            do {
                print("🚀 Starting async analysis...")
                let analysis = try await APIClient.shared.analyzeClothing(imageData: imageData)

                // Get image URL (prefer extracted, fallback to original)
                let imageUrl = analysis.extracted_image_url ?? analysis.original_image_url ?? ""

                print("✅ Analysis complete: \(analysis.type)")
                print("📸 Image URL: \(imageUrl)")

                // Create real item with analysis data
                let realItem = ClothingItem(
                    id: placeholderId,  // Same ID to replace placeholder
                    imagePath: imageUrl,
                    type: analysis.type,
                    color: analysis.color,
                    pattern: analysis.pattern,
                    style: analysis.style,
                    season: analysis.season,
                    pairsWellWith: analysis.pairs_well_with,
                    confidence: analysis.confidence,
                    isProcessing: false
                )

                // Update the placeholder with real data
                wardrobeVM.updateItem(placeholderId, with: realItem)

                print("💾 Item updated in closet!")

            } catch {
                print("❌ Analysis failed: \(error)")
                // Remove the placeholder on error
                wardrobeVM.deleteItem(placeholder)
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
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingScanner = false
    @State private var showingEditMetadata: ClothingItem?
    @State private var selectedFilter = "All"

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    let filterCategories = ["All", "Shirt", "Pants", "Dress", "Jacket", "Shoes", "Accessories"]

    var filteredItems: [ClothingItem] {
        // Use ACTUAL wardrobe items from Core Data, not samples!
        if selectedFilter == "All" {
            return wardrobeVM.items
        } else {
            return wardrobeVM.items.filter { $0.type.lowercased().contains(selectedFilter.lowercased()) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MVP-C.5: Filter by Category
                if !wardrobeVM.items.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filterCategories, id: \.self) { category in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = category
                                    }
                                }) {
                                    Text(category)
                                        .font(.system(size: 14, weight: selectedFilter == category ? .semibold : .medium))
                                        .foregroundColor(selectedFilter == category ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedFilter == category ?
                                                LinearGradient(
                                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ) :
                                                LinearGradient(
                                                    colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white)
                }

            ScrollView {
                if wardrobeVM.items.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 64, weight: .ultraLight))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Your Closet is Empty")
                            .font(.system(size: 24, weight: .bold))

                        Text("Start by scanning your first item")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Button(action: { showingScanner = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                Text("Add Item")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(width: 200, height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredItems) { item in
                            WardrobeCard(item: item)
                                .onTapGesture {
                                    // MVP-C.4: Tap to edit metadata
                                    showingEditMetadata = item
                                }
                                .contextMenu {
                                    Button {
                                        showingEditMetadata = item
                                    } label: {
                                        Label("Edit Metadata", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        wardrobeVM.deleteItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(hex: "F8F9FA"))
            .navigationTitle("My Closet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingScanner = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerSheetView()
                    .environmentObject(wardrobeVM)
            }
            .sheet(item: $showingEditMetadata) { item in
                EditMetadataView(item: .constant(item)) { updatedItem in
                    // Update in Core Data
                    wardrobeVM.deleteItem(item)
                    wardrobeVM.addItem(updatedItem, imageData: nil)
                }
            }
            }
        }
    }
}

struct WardrobeCard: View {
    let item: ClothingItem
    @State private var itemImage: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Container with actual image or gradient background
            ZStack {
                if let image = itemImage {
                    // Display actual clothing image (background removed)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 160)
                        .background(Color.white)
                } else {
                    // Fallback gradient + icon while loading
                    LinearGradient(
                        colors: [
                            Color(hex: "6366F1").opacity(0.08),
                            Color(hex: "8B5CF6").opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    if item.isProcessing {
                        // Show loading indicator
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "6366F1")))
                                .scaleEffect(1.5)

                            Text("AI Analyzing...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "6366F1"))
                        }
                    } else {
                        Image(systemName: iconForType(item.type))
                            .font(.system(size: 56, weight: .ultraLight))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Info Section
            VStack(alignment: .leading, spacing: 6) {
                Text(item.isProcessing ? "Processing..." : item.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(item.isProcessing ? .secondary : .primary)
                    .lineLimit(1)

                Text(item.isProcessing ? "AI is analyzing" : item.style)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .shadow(color: Color(hex: "6366F1").opacity(item.isProcessing ? 0.2 : 0.1), radius: 20, x: 0, y: 8)
        .task(id: item.id) {
            // Load image when card appears or when item updates
            if !item.isProcessing && !item.imagePath.isEmpty {
                print("🔄 Loading image for: \(item.displayName), URL: \(item.imagePath)")
                loadImage()
            } else if item.imagePath.isEmpty {
                print("⚠️  No image path for: \(item.displayName)")
            }
        }
        .onChange(of: item.imagePath) { oldValue, newValue in
            // Reload when URL changes (placeholder -> real item)
            if !newValue.isEmpty && !item.isProcessing {
                print("🔄 Image path changed, reloading: \(item.displayName)")
                loadImage()
            }
        }
    }

    func loadImage() {
        Task {
            // Load from Tigris URL (stored in imagePath)
            guard !item.imagePath.isEmpty, let url = URL(string: item.imagePath) else {
                print("No image URL for \(item.displayName)")
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.itemImage = image
                    }
                    print("✅ Loaded image from Tigris: \(item.displayName)")
                }
            } catch {
                print("❌ Failed to load image from \(url): \(error)")
            }
        }
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
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @StateObject private var savedOutfitsManager = SavedOutfitsManager()
    @State private var selectedTab = 0  // 0 = Generate, 1 = Saved
    @State private var occasion = "Work"
    @State private var isGenerating = false
    @State private var generatedOutfits: [OutfitSuggestion] = []  // Multiple outfits
    @State private var showOutfitsSheet = false  // Show in popup
    @State private var weatherEnabled = true
    @State private var city = "San Francisco"

    let occasions = [
        ("Work", "briefcase.fill", "4B5563"),
        ("Casual", "house.fill", "10B981"),
        ("Date Night", "heart.fill", "EC4899"),
        ("Gym", "figure.run", "F59E0B"),
        ("Formal", "star.fill", "8B5CF6"),
        ("Party", "sparkles", "EF4444")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F9FA").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Empty state if no closet items
                        if wardrobeVM.items.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "tshirt.fill")
                                    .font(.system(size: 64, weight: .ultraLight))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("Add Items to Your Closet")
                                    .font(.system(size: 24, weight: .bold))

                                Text("AI can't style an empty closet!\nAdd some items to get outfit suggestions.")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 120)
                        } else {
                            // Compact Header
                            VStack(spacing: 8) {
                                Text("AI Outfit Stylist")
                                    .font(.system(size: 28, weight: .bold))

                                Text("Using \(wardrobeVM.items.count) items from your closet")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 12)

                        // Occasion Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(occasions, id: \.0) { occ in
                                OccasionCard(
                                    title: occ.0,
                                    icon: occ.1,
                                    color: occ.2,
                                    isSelected: occasion == occ.0
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        occasion = occ.0
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Generate Button
                        Button(action: generateOutfit) {
                            HStack(spacing: 12) {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.95)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                Text(isGenerating ? "Creating Your Look..." : "Generate Outfit")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 20, x: 0, y: 10)
                        }
                        .disabled(isGenerating)
                        .padding(.horizontal, 20)

                        // Old UI - Remove this block
                        if false, let outfit = generatedOutfits.first {
                            VStack(spacing: 20) {
                                // Success Header
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "10B981"))

                                    Text("Your Perfect Outfit")
                                        .font(.system(size: 24, weight: .bold))
                                }
                                .padding(.top, 8)

                                // Items with beautiful cards
                                VStack(spacing: 12) {
                                    ForEach(outfit.items, id: \.id) { item in
                                        OutfitItemCard(item: item)
                                    }
                                }
                                .padding(.horizontal, 20)

                                // Reasoning Card
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(Color(hex: "6366F1").opacity(0.15))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "lightbulb.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(
                                                        LinearGradient(
                                                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            )

                                        Text("Why This Works")
                                            .font(.system(size: 19, weight: .semibold))
                                    }

                                    Text(outfit.reasoning)
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(6)
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                                .padding(.horizontal, 20)

                                // Style Tips Card
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(Color(hex: "8B5CF6").opacity(0.15))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "sparkles")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(
                                                        LinearGradient(
                                                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            )

                                        Text("Pro Tips")
                                            .font(.system(size: 19, weight: .semibold))
                                    }

                                    Text(outfit.styleTips)
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(6)
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                                .padding(.horizontal, 20)

                                // Voice Player
                                if outfit.audioURL != nil {
                                    AudioPlayerView(audioURL: outfit.audioURL)
                                        .padding(.horizontal, 20)
                                }

                                // Action Buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            generatedOutfits = []
                                        }
                                    }) {
                                        Text("Try Again")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(hex: "6366F1"))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 52)
                                            .background(Color(hex: "6366F1").opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }

                                    Button(action: {}) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "heart.fill")
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
                                .padding(.bottom, 8)
                            }
                        }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .sheet(isPresented: $showOutfitsSheet) {
            OutfitsSheetView(
                outfits: generatedOutfits,
                wardrobeItems: wardrobeVM.items,
                savedOutfitsManager: savedOutfitsManager,
                isPresented: $showOutfitsSheet
            )
        }
    }

    func generateOutfit() {
        // Check if user has items in closet
        guard !wardrobeVM.items.isEmpty else {
            return
        }

        isGenerating = true
        generatedOutfits = []

        Task {
            do {
                // SMART CLAUDE MATCHING: Send all items, Claude picks best combinations
                print("🤖 Getting Claude-powered outfit matching...")
                let matchedOutfits = try await APIClient.shared.getSmartOutfits(
                    occasion: occasion,
                    wardrobeItems: wardrobeVM.items,
                    weather: weatherEnabled ? Weather(temperature: 72, condition: "Clear") : nil
                )

                print("✅ Claude matched \(matchedOutfits.count) outfit variations")

                // Convert to OutfitSuggestion format
                var outfits: [OutfitSuggestion] = []

                for matched in matchedOutfits {
                    // Convert item IDs to OutfitItem objects
                    let outfitItems = matched.items.compactMap { itemId -> OutfitSuggestion.OutfitItem? in
                        guard let item = wardrobeVM.items.first(where: { $0.id.uuidString == itemId }) else {
                            return nil
                        }
                        return OutfitSuggestion.OutfitItem(
                            id: item.id.uuidString,
                            type: item.type,
                            reasoning: matched.vibe
                        )
                    }

                    let outfit = OutfitSuggestion(
                        occasion: matched.name,
                        items: outfitItems,
                        reasoning: matched.vibe,
                        styleTips: matched.stylingTips,
                        weatherTemp: 72.0,
                        weatherCondition: "Clear"
                    )

                    outfits.append(outfit)
                }

                print("✅ Created \(outfits.count) complete outfits with images")

                await MainActor.run {
                    generatedOutfits = outfits
                    isGenerating = false
                    showOutfitsSheet = true  // Show popup!
                }
            } catch {
                print("❌ Outfit generation error: \(error)")
                await MainActor.run {
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Occasion Card

struct OccasionCard: View {
    let title: String
    let icon: String
    let color: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: color).opacity(isSelected ? 0.15 : 0.08))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(hex: color))
                }

                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.white : Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? Color(hex: color).opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: isSelected ? Color(hex: color).opacity(0.15) : Color.clear, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Outfit Item Card

struct OutfitItemCard: View {
    let item: OutfitSuggestion.OutfitItem

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "6366F1").opacity(0.1), Color(hex: "8B5CF6").opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: iconForType(item.type))
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.type.capitalized)
                    .font(.system(size: 17, weight: .semibold))

                Text(item.reasoning)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "10B981"))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
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

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @State private var enableVoice = true
    @State private var enableWeather = true
    @State private var backendURL = "http://localhost:8000"

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
                            Text("Version 2.0 - MVP Edition")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Closet") {
                    HStack {
                        Image(systemName: "tshirt.fill")
                            .foregroundColor(Color(hex: "6366F1"))
                        Text("Total Items")
                            .font(.system(size: 17))
                        Spacer()
                        Text("\(wardrobeVM.items.count)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                Section("Features") {
                    Toggle(isOn: $enableVoice) {
                        Label {
                            Text("Voice Recommendations")
                                .font(.system(size: 17))
                        } icon: {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(Color(hex: "6366F1"))
                        }
                    }

                    Toggle(isOn: $enableWeather) {
                        Label {
                            Text("Weather-Aware Outfits")
                                .font(.system(size: 17))
                        } icon: {
                            Image(systemName: "cloud.sun.fill")
                                .foregroundColor(Color(hex: "F59E0B"))
                        }
                    }

                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(Color(hex: "10B981"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto Cloud Backup")
                                .font(.system(size: 17))
                            Text("Encrypted backup on every save")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
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
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
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
