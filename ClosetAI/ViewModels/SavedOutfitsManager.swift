/**
 * Saved Outfits Manager
 *
 * Manages locally saved outfit combinations for virtual try-on.
 */

import Foundation
import Combine

@MainActor
class SavedOutfitsManager: ObservableObject {
    @Published var savedOutfits: [SavedOutfit] = []

    private let userDefaultsKey = "savedOutfits"

    init() {
        loadOutfits()
    }

    /// Save an outfit
    func saveOutfit(_ outfit: OutfitSuggestion, wardrobeItems: [ClothingItem]) {
        // Convert OutfitSuggestion to SavedOutfit
        let itemIds = outfit.items.compactMap { outfitItem -> UUID? in
            UUID(uuidString: outfitItem.id)
        }

        let savedOutfit = SavedOutfit(
            name: outfit.occasion,
            occasion: outfit.occasion,
            itemIds: itemIds,
            stylingTips: outfit.styleTips,
            vibe: outfit.reasoning
        )

        savedOutfits.append(savedOutfit)
        persist()

        print("💾 Saved outfit: \(savedOutfit.name)")
    }

    /// Delete an outfit
    func deleteOutfit(_ outfit: SavedOutfit) {
        savedOutfits.removeAll { $0.id == outfit.id }
        persist()
    }

    /// Load outfits from UserDefaults
    private func loadOutfits() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([SavedOutfit].self, from: data) {
            savedOutfits = decoded
            print("📦 Loaded \(savedOutfits.count) saved outfits")
        }
    }

    /// Persist to UserDefaults
    private func persist() {
        if let encoded = try? JSONEncoder().encode(savedOutfits) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}
