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

// MARK: - Scanner Sheet View

struct ScannerSheetView: View {
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: ClothingAnalysis?
    @State private var allItems: [ClothingAnalysis] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSaveSuccess = false
    @State private var itemsSaved = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Add to Closet")
                            .font(.system(size: 28, weight: .bold))

                        Text("AI will auto-generate all metadata")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)

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
                        VStack(spacing: 12) {
                            // Camera Button (only show if camera is available)
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button(action: { showingCamera = true }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "6366F1").opacity(0.1))
                                                .frame(width: 56, height: 56)

                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(Color(hex: "6366F1"))
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Take Photo")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text("Use camera to scan clothing")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                            }

                            // Photo Library Button
                            Button(action: { showingImagePicker = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "8B5CF6").opacity(0.1))
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color(hex: "8B5CF6"))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Choose Photo")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Text("Pick from your photo library")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
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

                                if allItems.count > 1 {
                                    Text("Found \(allItems.count) Items!")
                                        .font(.system(size: 20, weight: .semibold))
                                } else {
                                    Text("Analysis Complete")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, 20)

                            // Show all extracted items
                            if allItems.count > 1 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(allItems.enumerated()), id: \.offset) { index, item in
                                            VStack(spacing: 8) {
                                                // Show extracted image if available
                                                if let extractedBase64 = item.extracted_image,
                                                   let imageData = Data(base64Encoded: extractedBase64),
                                                   let uiImage = UIImage(data: imageData) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 120, height: 120)
                                                        .background(Color.white)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                } else {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.gray.opacity(0.1))
                                                            .frame(width: 120, height: 120)

                                                        Image(systemName: "tshirt")
                                                            .font(.system(size: 40))
                                                            .foregroundColor(.gray)
                                                    }
                                                }

                                                Text("\(item.color) \(item.type)")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(width: 120)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }

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

                            // Action Buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedImage = nil
                                        analysisResult = nil
                                    }
                                }) {
                                    Text("Scan Another")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "6366F1"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(Color(hex: "6366F1").opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }

                                Button(action: saveToWardrobe) {
                                    HStack(spacing: 8) {
                                        Image(systemName: showingSaveSuccess ? "checkmark" : "plus.circle.fill")
                                            .font(.system(size: 15))

                                        if showingSaveSuccess {
                                            Text("Saved \(itemsSaved) item(s)!")
                                                .font(.system(size: 16, weight: .semibold))
                                        } else if allItems.count > 1 {
                                            Text("Save All \(allItems.count) Items")
                                                .font(.system(size: 16, weight: .semibold))
                                        } else {
                                            Text("Save to Closet")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        LinearGradient(
                                            colors: showingSaveSuccess ?
                                                [Color(hex: "10B981"), Color(hex: "10B981")] :
                                                [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .disabled(showingSaveSuccess)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(hex: "FFFFFF"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
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

                        // Debug logging
                        print("📊 Analysis received:")
                        print("  - Type: \(analysis.type)")
                        print("  - Color: \(analysis.color)")
                        print("  - item_count: \(analysis.item_count ?? 0)")
                        print("  - all_items: \(analysis.all_items?.count ?? 0) items")

                        // Check if multiple items detected
                        if let allItemsData = analysis.all_items, !allItemsData.isEmpty {
                            allItems = allItemsData
                            print("✅ Detected \(allItemsData.count) items!")
                            print("  Items: \(allItemsData.map { "\($0.color) \($0.type)" })")
                        } else {
                            allItems = [analysis]
                            print("ℹ️  Single item mode")
                        }

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

    func saveToWardrobe() {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.8) else {
            return
        }

        // Save ALL detected items
        let itemsToSave = allItems.isEmpty ? (analysisResult.map { [$0] } ?? []) : allItems

        itemsSaved = 0

        for itemAnalysis in itemsToSave {
            // Create ClothingItem from each analysis
            let item = ClothingItem(
                imagePath: "",
                type: itemAnalysis.type,
                color: itemAnalysis.color,
                pattern: itemAnalysis.pattern,
                style: itemAnalysis.style,
                season: itemAnalysis.season,
                pairsWellWith: itemAnalysis.pairs_well_with,
                confidence: itemAnalysis.confidence
            )

            // Save to wardrobe
            wardrobeVM.addItem(item, imageData: imageData)
            itemsSaved += 1
        }

        withAnimation(.spring(response: 0.3)) {
            showingSaveSuccess = true
        }

        // Close sheet and reset after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Container with gradient background
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "6366F1").opacity(0.08),
                        Color(hex: "8B5CF6").opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

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
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Info Section
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.style)
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
        .shadow(color: Color(hex: "6366F1").opacity(0.1), radius: 20, x: 0, y: 8)
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
    @State private var occasion = "Work"
    @State private var isGenerating = false
    @State private var generatedOutfit: OutfitSuggestion?
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

                        // Results
                        if let outfit = generatedOutfit {
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
                                            generatedOutfit = nil
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
    }

    func generateOutfit() {
        // Check if user has items in closet
        guard !wardrobeVM.items.isEmpty else {
            return
        }

        isGenerating = true
        generatedOutfit = nil

        Task {
            do {
                // Use user's ACTUAL closet items!
                let outfit = try await APIClient.shared.generateOutfit(
                    wardrobeItems: wardrobeVM.items,
                    occasion: occasion,
                    weather: weatherEnabled ? Weather(temperature: 72, condition: "Clear") : nil
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
