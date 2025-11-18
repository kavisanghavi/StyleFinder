/**
 * Edit Metadata View
 *
 * MVP-C.4: Allow users to manually edit/correct any auto-generated metadata
 * Provides dropdown lists and custom text input for all fields
 */

import SwiftUI

struct EditMetadataView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var item: ClothingItem
    let onSave: (ClothingItem) -> Void

    @State private var selectedType: String
    @State private var selectedColor: String
    @State private var selectedStyle: String
    @State private var selectedPattern: String
    @State private var selectedOccasions: Set<String>
    @State private var selectedSeasons: Set<String>
    @State private var customType = ""
    @State private var customColor = ""

    // Predefined options
    let types = ["Shirt", "T-Shirt", "Blouse", "Pants", "Jeans", "Dress", "Skirt", "Jacket", "Coat", "Sweater", "Shoes", "Accessory", "Custom"]
    let colors = ["Black", "White", "Gray", "Red", "Blue", "Green", "Yellow", "Orange", "Purple", "Pink", "Brown", "Beige", "Custom"]
    let styles = ["Casual", "Formal", "Business Casual", "Athletic", "Elegant", "Bohemian", "Vintage", "Modern", "Street", "Preppy"]
    let patterns = ["Solid", "Striped", "Floral", "Checkered", "Polka Dot", "Geometric", "Abstract", "Animal Print"]
    let occasions = ["Work", "Casual", "Formal", "Party", "Sports", "Date Night", "Wedding", "Beach", "Travel"]
    let seasons = ["Spring", "Summer", "Fall", "Winter"]

    init(item: Binding<ClothingItem>, onSave: @escaping (ClothingItem) -> Void) {
        self._item = item
        self.onSave = onSave

        // Initialize states
        _selectedType = State(initialValue: item.wrappedValue.type.capitalized)
        _selectedColor = State(initialValue: item.wrappedValue.color.capitalized)
        _selectedStyle = State(initialValue: item.wrappedValue.style.capitalized)
        _selectedPattern = State(initialValue: item.wrappedValue.pattern.capitalized)
        _selectedOccasions = State(initialValue: Set(item.wrappedValue.occasion ?? []))
        _selectedSeasons = State(initialValue: Set(item.wrappedValue.season))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type Section
                Section("Category / Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }

                    if selectedType == "Custom" {
                        TextField("Enter custom type", text: $customType)
                    }
                }

                // Color Section
                Section("Color") {
                    Picker("Primary Color", selection: $selectedColor) {
                        ForEach(colors, id: \.self) { color in
                            Text(color).tag(color)
                        }
                    }

                    if selectedColor == "Custom" {
                        TextField("Enter custom color", text: $customColor)
                    }
                }

                // Style Section
                Section("Style") {
                    Picker("Style", selection: $selectedStyle) {
                        ForEach(styles, id: \.self) { style in
                            Text(style).tag(style)
                        }
                    }
                }

                // Pattern Section
                Section("Pattern") {
                    Picker("Pattern", selection: $selectedPattern) {
                        ForEach(patterns, id: \.self) { pattern in
                            Text(pattern).tag(pattern)
                        }
                    }
                }

                // Occasions Section
                Section("Occasions") {
                    ForEach(occasions, id: \.self) { occasion in
                        Toggle(occasion, isOn: Binding(
                            get: { selectedOccasions.contains(occasion) },
                            set: { isSelected in
                                if isSelected {
                                    selectedOccasions.insert(occasion)
                                } else {
                                    selectedOccasions.remove(occasion)
                                }
                            }
                        ))
                    }
                }

                // Seasons Section
                Section("Seasons") {
                    ForEach(seasons, id: \.self) { season in
                        Toggle(season, isOn: Binding(
                            get: { selectedSeasons.contains(season) },
                            set: { isSelected in
                                if isSelected {
                                    selectedSeasons.insert(season)
                                } else {
                                    selectedSeasons.remove(season)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Edit Metadata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    func saveChanges() {
        // Determine final type
        let finalType = selectedType == "Custom" ? customType : selectedType

        // Determine final color
        let finalColor = selectedColor == "Custom" ? customColor : selectedColor

        // Create updated item
        let updatedItem = ClothingItem(
            id: item.id,
            imagePath: item.imagePath,
            type: finalType,
            color: finalColor,
            pattern: selectedPattern,
            style: selectedStyle,
            season: Array(selectedSeasons),
            pairsWellWith: item.pairsWellWith,
            confidence: item.confidence,
            material: item.material,
            occasion: Array(selectedOccasions),
            careInstructions: item.careInstructions,
            dateAdded: item.dateAdded,
            lastWorn: item.lastWorn,
            wornCount: item.wornCount,
            favorite: item.favorite,
            userNotes: item.userNotes,
            userTags: item.userTags
        )

        onSave(updatedItem)
        dismiss()
    }
}

#Preview {
    EditMetadataView(
        item: .constant(ClothingItem.samples[0]),
        onSave: { _ in }
    )
}
