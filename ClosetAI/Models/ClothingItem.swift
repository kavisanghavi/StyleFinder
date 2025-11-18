/**
 * ClothingItem Model
 *
 * Represents a single clothing item in the user's wardrobe.
 * Stores all metadata from Claude's analysis including type, color, style, etc.
 *
 * Features:
 * - Codable for JSON serialization
 * - Identifiable for SwiftUI lists
 * - All properties from Claude API response
 */

import Foundation
import SwiftUI

struct ClothingItem: Identifiable, Codable, Hashable {
    // MARK: - Properties

    let id: UUID
    let imagePath: String  // Local file path to the encrypted image

    // Claude Analysis Results
    let type: String  // shirt, pants, dress, etc.
    let color: String  // Primary color
    let pattern: String  // solid, striped, floral, etc.
    let style: String  // casual, formal, athletic, etc.
    let season: [String]  // ["spring", "summer", "fall", "winter"]
    let pairsWellWith: [String]  // List of complementary items
    let confidence: Double  // Analysis confidence (0.0 - 1.0)

    // Optional Properties
    let material: String?  // cotton, polyester, silk, etc.
    let occasion: [String]?  // work, casual, formal, etc.
    let careInstructions: String?

    // Metadata
    let dateAdded: Date
    let lastWorn: Date?
    let wornCount: Int
    let favorite: Bool

    // User Notes
    let userNotes: String?
    let userTags: [String]

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        imagePath: String,
        type: String,
        color: String,
        pattern: String,
        style: String,
        season: [String],
        pairsWellWith: [String],
        confidence: Double,
        material: String? = nil,
        occasion: [String]? = nil,
        careInstructions: String? = nil,
        dateAdded: Date = Date(),
        lastWorn: Date? = nil,
        wornCount: Int = 0,
        favorite: Bool = false,
        userNotes: String? = nil,
        userTags: [String] = []
    ) {
        self.id = id
        self.imagePath = imagePath
        self.type = type
        self.color = color
        self.pattern = pattern
        self.style = style
        self.season = season
        self.pairsWellWith = pairsWellWith
        self.confidence = confidence
        self.material = material
        self.occasion = occasion
        self.careInstructions = careInstructions
        self.dateAdded = dateAdded
        self.lastWorn = lastWorn
        self.wornCount = wornCount
        self.favorite = favorite
        self.userNotes = userNotes
        self.userTags = userTags
    }

    // MARK: - Computed Properties

    var displayName: String {
        return "\(color) \(type)"
    }

    var seasonEmojis: String {
        season.map { seasonEmoji(for: $0) }.joined()
    }

    // MARK: - Helper Methods

    private func seasonEmoji(for season: String) -> String {
        switch season.lowercased() {
        case "spring": return "🌸"
        case "summer": return "☀️"
        case "fall", "autumn": return "🍂"
        case "winter": return "❄️"
        default: return ""
        }
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "type": type,
            "color": color,
            "pattern": pattern,
            "style": style,
            "season": season,
            "pairs_well_with": pairsWellWith,
            "confidence": confidence,
            "material": material as Any,
            "occasion": occasion as Any
        ]
    }
}

// MARK: - Sample Data for Preview

#if DEBUG
extension ClothingItem {
    static var sample: ClothingItem {
        ClothingItem(
            imagePath: "sample_image.jpg",
            type: "shirt",
            color: "blue",
            pattern: "solid",
            style: "casual",
            season: ["spring", "summer", "fall"],
            pairsWellWith: ["jeans", "chinos", "shorts"],
            confidence: 0.95,
            material: "cotton",
            occasion: ["casual", "work"],
            careInstructions: "Machine wash cold, tumble dry low",
            dateAdded: Date(),
            favorite: true,
            userTags: ["favorite", "versatile"]
        )
    }

    static var samples: [ClothingItem] {
        [
            ClothingItem(
                imagePath: "sample1.jpg",
                type: "shirt",
                color: "white",
                pattern: "solid",
                style: "formal",
                season: ["spring", "summer", "fall", "winter"],
                pairsWellWith: ["dress pants", "suit jacket"],
                confidence: 0.98
            ),
            ClothingItem(
                imagePath: "sample2.jpg",
                type: "jeans",
                color: "blue",
                pattern: "solid",
                style: "casual",
                season: ["spring", "fall", "winter"],
                pairsWellWith: ["t-shirt", "sweater", "jacket"],
                confidence: 0.92
            ),
            ClothingItem(
                imagePath: "sample3.jpg",
                type: "dress",
                color: "red",
                pattern: "floral",
                style: "elegant",
                season: ["spring", "summer"],
                pairsWellWith: ["heels", "sandals", "cardigan"],
                confidence: 0.89
            )
        ]
    }
}
#endif
