/**
 * Saved Outfit Model
 *
 * Represents a user's saved outfit for virtual try-on.
 */

import Foundation

struct SavedOutfit: Identifiable, Codable {
    let id: UUID
    let name: String  // "Classic Look", "Modern Edge"
    let occasion: String  // "Work", "Casual"
    let itemIds: [UUID]  // References to ClothingItem IDs
    let stylingTips: String
    let vibe: String
    let dateSaved: Date

    init(
        id: UUID = UUID(),
        name: String,
        occasion: String,
        itemIds: [UUID],
        stylingTips: String,
        vibe: String,
        dateSaved: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.occasion = occasion
        self.itemIds = itemIds
        self.stylingTips = stylingTips
        self.vibe = vibe
        self.dateSaved = dateSaved
    }

    /// Get actual clothing items from wardrobe
    func getItems(from wardrobe: [ClothingItem]) -> [ClothingItem] {
        return itemIds.compactMap { id in
            wardrobe.first(where: { $0.id == id })
        }
    }
}
