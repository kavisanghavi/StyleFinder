/**
 * Core Data Persistence Controller
 *
 * Manages Core Data stack for local wardrobe storage.
 * Handles saving, fetching, updating, and deleting clothing items.
 */

import CoreData
import Foundation

class PersistenceController {
    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Core Data Stack

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ClosetAI")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    // MARK: - Preview Support

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create sample data for previews
        for i in 0..<3 {
            let item = ClothingItemEntity(context: context)
            item.id = UUID()
            item.type = ["shirt", "pants", "dress"][i]
            item.color = ["white", "blue", "red"][i]
            item.pattern = "solid"
            item.style = ["formal", "casual", "elegant"][i]
            item.season = ["spring", "summer", "fall", "winter"].joined(separator: ",")
            item.pairsWellWith = "blazer,shoes"
            item.confidence = 0.95
            item.imageData = nil
            item.createdAt = Date()
            item.lastWornAt = nil
        }

        try? context.save()
        return controller
    }()

    // MARK: - CRUD Operations

    /// Save a ClothingItem to Core Data (upsert: update if exists, insert if new)
    func saveClothingItem(_ item: ClothingItem, imageData: Data?) throws {
        let context = container.viewContext

        // Check if entity already exists
        let request = NSFetchRequest<ClothingItemEntity>(entityName: "ClothingItemEntity")
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)

        let existingEntities = try context.fetch(request)
        let entity: ClothingItemEntity

        if let existing = existingEntities.first {
            // Update existing entity
            entity = existing
        } else {
            // Create new entity
            entity = ClothingItemEntity(context: context)
            entity.id = item.id
            entity.createdAt = item.dateAdded
        }

        // Update all fields
        entity.type = item.type
        entity.color = item.color
        entity.pattern = item.pattern
        entity.style = item.style
        entity.season = item.season.joined(separator: ",")
        entity.pairsWellWith = item.pairsWellWith.joined(separator: ",")
        entity.confidence = item.confidence
        entity.lastWornAt = item.lastWorn

        // Store Tigris URL in imageData field as UTF-8 string data
        if !item.imagePath.isEmpty {
            entity.imageData = item.imagePath.data(using: .utf8)
        } else {
            entity.imageData = nil
        }

        try context.save()
    }

    /// Fetch all clothing items
    func fetchAllItems() throws -> [ClothingItem] {
        let request = NSFetchRequest<ClothingItemEntity>(entityName: "ClothingItemEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClothingItemEntity.createdAt, ascending: false)]

        let entities = try container.viewContext.fetch(request)
        return entities.compactMap { try? $0.toClothingItem() }
    }

    /// Load and decrypt image data for a specific item
    func loadImageData(for itemId: UUID) throws -> Data? {
        let request = NSFetchRequest<ClothingItemEntity>(entityName: "ClothingItemEntity")
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)

        if let entity = try container.viewContext.fetch(request).first,
           let encryptedData = entity.imageData {
            // Decrypt the image data
            return try? EncryptionService.shared.decrypt(data: encryptedData)
        }

        return nil
    }

    /// Fetch items filtered by type
    func fetchItems(ofType type: String) throws -> [ClothingItem] {
        let request = NSFetchRequest<ClothingItemEntity>(entityName: "ClothingItemEntity")
        request.predicate = NSPredicate(format: "type == %@", type)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClothingItemEntity.createdAt, ascending: false)]

        let entities = try container.viewContext.fetch(request)
        return entities.compactMap { try? $0.toClothingItem() }
    }

    /// Update last worn date
    func updateLastWorn(_ itemId: UUID, date: Date) throws {
        let request = NSFetchRequest<ClothingItemEntity>(entityName: "ClothingItemEntity")
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)

        if let entity = try container.viewContext.fetch(request).first {
            entity.lastWornAt = date
            try container.viewContext.save()
        }
    }

    /// Delete a clothing item
    func deleteItem(_ itemId: UUID) throws {
        let request = NSFetchRequest<ClothingItemEntity>(entityName: "ClothingItemEntity")
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)

        if let entity = try container.viewContext.fetch(request).first {
            container.viewContext.delete(entity)
            try container.viewContext.save()
        }
    }

    /// Delete all items (for testing/reset)
    func deleteAllItems() throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ClothingItemEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        try container.viewContext.execute(deleteRequest)
        try container.viewContext.save()
    }

    // MARK: - Statistics

    /// Get wardrobe statistics
    func getStatistics() throws -> WardrobeStatistics {
        let items = try fetchAllItems()

        let typeCount = Dictionary(grouping: items, by: { $0.type })
            .mapValues { $0.count }

        let colorCount = Dictionary(grouping: items, by: { $0.color })
            .mapValues { $0.count }

        return WardrobeStatistics(
            totalItems: items.count,
            itemsByType: typeCount,
            itemsByColor: colorCount,
            recentlyAdded: items.prefix(5).map { $0.id }
        )
    }
}

// MARK: - Wardrobe Statistics

struct WardrobeStatistics {
    let totalItems: Int
    let itemsByType: [String: Int]
    let itemsByColor: [String: Int]
    let recentlyAdded: [UUID]
}

// MARK: - Core Data Extension

extension ClothingItemEntity {
    /// Convert Core Data entity to ClothingItem model
    func toClothingItem() throws -> ClothingItem {
        guard let id = id,
              let type = type,
              let color = color,
              let pattern = pattern,
              let style = style,
              let season = season,
              let pairsWellWith = pairsWellWith,
              let createdAt = createdAt else {
            throw PersistenceError.invalidData
        }

        // Load Tigris URL from imageData (stored as UTF-8 string)
        var imageUrl = ""
        if let imageData = imageData, let urlString = String(data: imageData, encoding: .utf8) {
            imageUrl = urlString
        }

        return ClothingItem(
            id: id,
            imagePath: imageUrl,
            type: type,
            color: color,
            pattern: pattern,
            style: style,
            season: season.components(separatedBy: ","),
            pairsWellWith: pairsWellWith.components(separatedBy: ","),
            confidence: confidence,
            dateAdded: createdAt,
            lastWorn: lastWornAt
        )
    }
}

enum PersistenceError: LocalizedError {
    case invalidData
    case saveFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .invalidData: return "Invalid data format"
        case .saveFailed: return "Failed to save to database"
        case .fetchFailed: return "Failed to fetch from database"
        }
    }
}
