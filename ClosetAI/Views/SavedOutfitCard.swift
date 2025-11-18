import SwiftUI

struct SavedOutfitCard: View {
    let outfit: SavedOutfit
    let wardrobeItems: [ClothingItem]
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Preview image (first item)
            if let firstItemId = outfit.itemIds.first,
               let firstItem = wardrobeItems.first(where: { $0.id == firstItemId }) {
                WardrobeCard(item: firstItem)
            }

            // Outfit info
            VStack(spacing: 4) {
                Text(outfit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                Text("\(outfit.itemIds.count) items")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}
