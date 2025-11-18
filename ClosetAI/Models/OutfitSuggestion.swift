/**
 * OutfitSuggestion Model
 *
 * Represents an AI-generated outfit suggestion from Claude.
 * Contains the selected items, reasoning, styling tips, and optional voice audio URL.
 */

import Foundation

struct OutfitSuggestion: Identifiable, Codable {
    // MARK: - Properties

    let id: UUID
    let occasion: String
    let items: [OutfitItem]
    let reasoning: String
    let styleTips: String
    let audioURL: String?  // ElevenLabs voice recommendation
    let colorHarmony: String?
    let alternatives: [AlternativeItem]?
    let createdAt: Date

    // Weather context (if used)
    let weatherTemp: Double?
    let weatherCondition: String?

    // MARK: - Nested Types

    struct OutfitItem: Identifiable, Codable, Hashable {
        let id: String  // Matches ClothingItem ID
        let type: String
        let reasoning: String

        var clothingItemId: UUID? {
            UUID(uuidString: id)
        }
    }

    struct AlternativeItem: Identifiable, Codable, Hashable {
        let id: String
        let type: String
        let reason: String

        var clothingItemId: UUID? {
            UUID(uuidString: id)
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        occasion: String,
        items: [OutfitItem],
        reasoning: String,
        styleTips: String,
        audioURL: String? = nil,
        colorHarmony: String? = nil,
        alternatives: [AlternativeItem]? = nil,
        createdAt: Date = Date(),
        weatherTemp: Double? = nil,
        weatherCondition: String? = nil
    ) {
        self.id = id
        self.occasion = occasion
        self.items = items
        self.reasoning = reasoning
        self.styleTips = styleTips
        self.audioURL = audioURL
        self.colorHarmony = colorHarmony
        self.alternatives = alternatives
        self.createdAt = createdAt
        self.weatherTemp = weatherTemp
        self.weatherCondition = weatherCondition
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case occasion
        case items
        case reasoning
        case styleTips = "style_tips"
        case audioURL = "audio_url"
        case colorHarmony = "color_harmony"
        case alternatives
        case createdAt = "created_at"
        case weatherTemp = "weather_temp"
        case weatherCondition = "weather_condition"
    }
}

// MARK: - Sample Data for Preview

#if DEBUG
extension OutfitSuggestion {
    static var sample: OutfitSuggestion {
        OutfitSuggestion(
            occasion: "Work Meeting",
            items: [
                OutfitItem(
                    id: UUID().uuidString,
                    type: "shirt",
                    reasoning: "Professional white shirt creates a clean, polished base"
                ),
                OutfitItem(
                    id: UUID().uuidString,
                    type: "pants",
                    reasoning: "Navy dress pants complement the shirt perfectly"
                ),
                OutfitItem(
                    id: UUID().uuidString,
                    type: "blazer",
                    reasoning: "Adds authority and completes the professional look"
                )
            ],
            reasoning: "This outfit combines classic professionalism with modern style. The color palette is conservative yet confident, perfect for making a strong impression.",
            styleTips: "Roll up the sleeves slightly for a more approachable look. Add a simple watch for a finishing touch.",
            colorHarmony: "Navy and white create a timeless, sophisticated combination",
            alternatives: [
                AlternativeItem(
                    id: UUID().uuidString,
                    type: "shirt",
                    reason: "Light blue shirt for a softer, more creative look"
                )
            ],
            createdAt: Date(),
            weatherTemp: 72.0,
            weatherCondition: "Partly Cloudy"
        )
    }
}
#endif
