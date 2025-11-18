/**
 * Outfit Card View
 *
 * Swipeable card displaying a complete outfit with clothing item images.
 */

import SwiftUI

struct OutfitCardView: View {
    let outfit: OutfitSuggestion
    let wardrobeItems: [ClothingItem]

    var body: some View {
        VStack(spacing: 0) {
            // Card Header
            VStack(spacing: 8) {
                Text(outfit.occasion)
                    .font(.system(size: 28, weight: .bold))

                Text(outfit.reasoning)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            // Clothing Items Grid with Images
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(outfit.items, id: \.id) { outfitItem in
                    if let clothingItem = wardrobeItems.first(where: { $0.id.uuidString == outfitItem.id }) {
                        OutfitItemImageCard(item: clothingItem)
                    }
                }
            }
            .padding(20)

            // Styling Tips
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color(hex: "6366F1"))
                    Text("Styling Tips")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(outfit.styleTips)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "F8F9FA"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            // Save Button
            Button(action: {
                // TODO: Save outfit
                print("💾 Saving outfit: \(outfit.occasion)")
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                    Text("Save This Outfit")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Outfit Item Image Card

struct OutfitItemImageCard: View {
    let item: ClothingItem
    @State private var itemImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 12) {
            // Image
            ZStack {
                if let image = itemImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                } else {
                    Color(hex: "F8F9FA")
                        .frame(height: 140)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "6366F1")))
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Item Info
            VStack(spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                Text(item.style)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .task {
            loadImage()
        }
    }

    func loadImage() {
        Task {
            guard !item.imagePath.isEmpty, let url = URL(string: item.imagePath) else {
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.itemImage = image
                    }
                }
            } catch {
                print("❌ Failed to load image: \(error)")
            }
        }
    }
}
