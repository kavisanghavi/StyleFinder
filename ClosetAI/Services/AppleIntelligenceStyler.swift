/**
 * Apple Intelligence Outfit Styler
 *
 * Uses on-device Apple Intelligence (iOS 26+) to match clothing items
 * to outfit recipes from the backend.
 */

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
class AppleIntelligenceStyler {

    static let shared = AppleIntelligenceStyler()

    private var isAvailable: Bool = false

    private init() {
        checkAvailability()
    }

    /// Check if Apple Intelligence is available
    private func checkAvailability() {
        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels)
            isAvailable = true
            print("✅ Apple Intelligence available for outfit styling")
            #else
            isAvailable = false
            print("⚠️  Apple Intelligence not available - requires iOS 26+ SDK")
            #endif
        } else {
            isAvailable = false
            print("⚠️  Apple Intelligence requires iOS 26+")
        }
    }

    /// Match clothing items to an outfit recipe using Apple Intelligence
    func matchItemsToRecipe(
        recipe: [String: String],
        availableItems: [ClothingItem],
        colorPalette: [String],
        stylingTips: String
    ) async throws -> [ClothingItem] {

        guard #available(iOS 26.0, *) else {
            // Fallback to simple matching
            return simpleMatch(recipe: recipe, items: availableItems)
        }

        #if canImport(FoundationModels)
        // Build SIMPLE context for Apple Intelligence (avoid triggering safety)
        let itemsList = availableItems.enumerated().map { index, item in
            "\(index). \(item.color) \(item.type)"
        }.joined(separator: "\n")

        let recipeDescription = recipe.map { category, criteria in
            "\(category): \(criteria)"
        }.joined(separator: "\n")

        let prompt = """
        Help me pick a great outfit from my closet.

        What I want to wear:
        \(recipeDescription)

        My available clothes:
        \(itemsList)

        Pick 2-4 items that go well together. Return just the numbers, one per line.

        Example:
        0
        3
        7
        """

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: Prompt(prompt))

            let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🤖 Apple Intelligence response:\n\(content)")

            // Parse item indices from response
            let indices = parseItemIndices(from: content)
            let selectedItems = indices.compactMap { index in
                index < availableItems.count ? availableItems[index] : nil
            }

            print("✅ Apple Intelligence selected \(selectedItems.count) items")
            return selectedItems

        } catch {
            print("⚠️  Apple Intelligence failed, using fallback: \(error)")
            return simpleMatch(recipe: recipe, items: availableItems)
        }

        #else
        return simpleMatch(recipe: recipe, items: availableItems)
        #endif
    }

    /// Parse item indices from AI response
    private func parseItemIndices(from text: String) -> [Int] {
        var indices: [Int] = []

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Look for plain number or [number] pattern
            if let index = Int(trimmed) {
                indices.append(index)
            } else if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let numberPart = trimmed.dropFirst().dropLast()
                if let index = Int(numberPart) {
                    indices.append(index)
                }
            }
        }

        return indices
    }

    /// Simple fallback matching without AI
    private func simpleMatch(recipe: [String: String], items: [ClothingItem]) -> [ClothingItem] {
        var selected: [ClothingItem] = []

        // Get formality level from recipe vibe/style
        let formalKeywords = ["formal", "business", "professional", "elegant", "polished"]
        let casualKeywords = ["casual", "relaxed", "comfortable"]

        // Simple type-based matching
        let typeMap: [String: [String]] = [
            "top": ["shirt", "blouse", "sweater", "sweatshirt", "top", "t-shirt", "tshirt"],
            "bottom": ["jeans", "pants", "skirt", "shorts"],
            "shoes": ["shoes", "sneakers", "boots", "heels", "sandals"],
            "dress": ["dress", "gown"],
            "outerwear": ["jacket", "coat", "blazer"]
        ]

        // First try to match items with appropriate occasion
        let recipeText = recipe.values.joined(separator: " ").lowercased()
        let isFormal = formalKeywords.contains(where: { recipeText.contains($0) })

        for (category, criteria) in recipe {
            let categoryLower = category.lowercased()
            let criteriaLower = criteria.lowercased()

            // Special handling for dress (can be a complete outfit)
            if categoryLower == "dress" || criteriaLower.contains("dress") {
                if let dress = items.first(where: { item in
                    item.type.lowercased().contains("dress") &&
                    (item.occasion?.contains(where: { isFormal ? $0.lowercased().contains("formal") : $0.lowercased().contains("casual") }) ?? false)
                }) {
                    selected.append(dress)
                    continue
                }
            }

            if let matchTypes = typeMap[categoryLower] {
                // Try to match with correct occasion first
                if let match = items.first(where: { item in
                    let typeMatches = matchTypes.contains(where: { item.type.lowercased().contains($0) })
                    let occasionMatches = item.occasion?.contains(where: {
                        isFormal ? $0.lowercased().contains("formal") : $0.lowercased().contains("casual")
                    }) ?? true
                    return typeMatches && occasionMatches
                }) {
                    selected.append(match)
                } else if let match = items.first(where: { item in
                    // Fallback: just match type
                    matchTypes.contains(where: { item.type.lowercased().contains($0) })
                }) {
                    selected.append(match)
                }
            }
        }

        return Array(selected.prefix(4))  // Max 4 items
    }
}
