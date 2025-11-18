/**
 * Wardrobe View Model
 *
 * Manages wardrobe state, Core Data persistence, and cloud sync.
 */

import Foundation
import SwiftUI
import Combine

@MainActor
class WardrobeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var items: [ClothingItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var statistics: WardrobeStatistics?

    // Cloud sync
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    // MARK: - Private Properties

    private let persistence = PersistenceController.shared
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Clear any sample/test data on first launch
        clearSampleDataIfNeeded()
        loadItems()
    }

    private func clearSampleDataIfNeeded() {
        // Check if this is first launch or if we have old sample data
        let hasCleared = UserDefaults.standard.bool(forKey: "hasClearedSampleData")
        if !hasCleared {
            try? persistence.deleteAllItems()
            UserDefaults.standard.set(true, forKey: "hasClearedSampleData")
            print("🧹 Cleared sample data - starting fresh")
        }
    }

    // MARK: - Core Data Operations

    /// Load all items from Core Data
    func loadItems() {
        isLoading = true

        Task {
            do {
                let loadedItems = try persistence.fetchAllItems()
                await MainActor.run {
                    self.items = loadedItems
                    self.isLoading = false
                    self.updateStatistics()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load wardrobe: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }

    /// Add a new clothing item
    func addItem(_ item: ClothingItem, imageData: Data?) {
        Task {
            do {
                try persistence.saveClothingItem(item, imageData: imageData)
                await MainActor.run {
                    self.items.insert(item, at: 0)
                    self.updateStatistics()
                }

                // Auto cloud backup after save
                if let userId = getUserId() {
                    await backupToCloudSilently(userId: userId)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save item: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    /// Update an existing item (used to replace placeholder with real data)
    func updateItem(_ itemId: UUID, with newItem: ClothingItem) {
        Task {
            do {
                // Save (upsert) - will update existing item with same ID
                try persistence.saveClothingItem(newItem, imageData: nil)

                await MainActor.run {
                    if let index = self.items.firstIndex(where: { $0.id == itemId }) {
                        self.items[index] = newItem
                    }
                    self.updateStatistics()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update item: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    /// Delete an item
    func deleteItem(_ item: ClothingItem) {
        Task {
            do {
                try persistence.deleteItem(item.id)
                await MainActor.run {
                    self.items.removeAll { $0.id == item.id }
                    self.updateStatistics()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete item: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    /// Mark item as worn
    func markAsWorn(_ item: ClothingItem) {
        Task {
            do {
                try persistence.updateLastWorn(item.id, date: Date())
                // Reload items to get updated version
                loadItems()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update item: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    /// Update statistics
    private func updateStatistics() {
        Task {
            do {
                let stats = try persistence.getStatistics()
                await MainActor.run {
                    self.statistics = stats
                }
            } catch {
                print("Failed to update statistics: \(error)")
            }
        }
    }

    // MARK: - Cloud Sync with Tigris

    /// Backup wardrobe to Tigris cloud storage
    func backupToCloud(userId: String) {
        isSyncing = true

        Task {
            do {
                // Prepare wardrobe data
                let wardrobeData = WardrobeBackup(
                    userId: userId,
                    items: items,
                    lastUpdated: Date()
                )

                // Convert to JSON
                let jsonData = try JSONEncoder().encode(wardrobeData)

                // Encrypt
                let encryptedData = try EncryptionService.shared.encrypt(data: jsonData)

                // Upload to Tigris via backend
                try await apiClient.backupWardrobe(userId: userId, encryptedData: encryptedData)

                await MainActor.run {
                    self.lastSyncDate = Date()
                    self.isSyncing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Cloud backup failed: \(error.localizedDescription)"
                    self.showError = true
                    self.isSyncing = false
                }
            }
        }
    }

    /// Restore wardrobe from Tigris cloud storage
    func restoreFromCloud(userId: String) {
        isSyncing = true

        Task {
            do {
                // Fetch encrypted backup from Tigris
                let encryptedData = try await apiClient.fetchBackup(userId: userId)

                // Decrypt
                let jsonData = try EncryptionService.shared.decrypt(data: encryptedData)

                // Decode
                let backup = try JSONDecoder().decode(WardrobeBackup.self, from: jsonData)

                // Save all items to Core Data
                for item in backup.items {
                    try persistence.saveClothingItem(item, imageData: nil)
                }

                await MainActor.run {
                    self.items = backup.items
                    self.lastSyncDate = backup.lastUpdated
                    self.isSyncing = false
                    self.updateStatistics()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Cloud restore failed: \(error.localizedDescription)"
                    self.showError = true
                    self.isSyncing = false
                }
            }
        }
    }

    // MARK: - Filtering

    /// Get items by type
    func items(ofType type: String) -> [ClothingItem] {
        items.filter { $0.type.lowercased() == type.lowercased() }
    }

    /// Get items by season
    func items(forSeason season: String) -> [ClothingItem] {
        items.filter { $0.season.contains { $0.lowercased() == season.lowercased() } }
    }

    /// Get recently added items
    var recentItems: [ClothingItem] {
        items.prefix(10).map { $0 }
    }

    // MARK: - Auto Backup Helpers

    /// Silent cloud backup (no loading UI)
    private func backupToCloudSilently(userId: String) async {
        do {
            let wardrobeData = WardrobeBackup(
                userId: userId,
                items: items,
                lastUpdated: Date()
            )

            let jsonData = try JSONEncoder().encode(wardrobeData)
            let encryptedData = try EncryptionService.shared.encrypt(data: jsonData)

            try await apiClient.backupWardrobe(userId: userId, encryptedData: encryptedData)

            await MainActor.run {
                self.lastSyncDate = Date()
            }

            print("✅ Auto-backup completed silently")
        } catch {
            // Fail silently - don't interrupt user experience
            print("⚠️  Auto-backup failed: \(error)")
        }
    }

    /// Get or create user ID
    private func getUserId() -> String? {
        // For MVP, use device ID or create one
        if let savedId = UserDefaults.standard.string(forKey: "userId") {
            return savedId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "userId")
            return newId
        }
    }
}

// MARK: - Wardrobe Backup Model

struct WardrobeBackup: Codable {
    let userId: String
    let items: [ClothingItem]
    let lastUpdated: Date
}
