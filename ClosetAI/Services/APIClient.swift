/**
 * API Client
 *
 * Handles all communication with the backend API hosted on Daytona.
 * Manages network requests to Claude, ElevenLabs, Nano Banana, and Tigris through the backend.
 *
 * Features:
 * - Type-safe API calls
 * - Error handling
 * - Multipart form data for image uploads
 * - JSON request/response handling
 */

import Foundation
import UIKit

// MARK: - Helper Functions

/// Get or create user ID
func getUserId() -> String {
    // For MVP, use device ID or create one
    if let savedId = UserDefaults.standard.string(forKey: "userId") {
        return savedId
    } else {
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "userId")
        return newId
    }
}

// MARK: - API Client

class APIClient {
    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Properties

    // TODO: Update this URL after deploying to Daytona
    private let baseURL = "http://localhost:8000"  // Change to Daytona URL

    private let session: URLSession

    // MARK: - Initialization

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public Methods

    /// Analyze a clothing item using Claude's vision API
    func analyzeClothing(imageData: Data) async throws -> ClothingAnalysis {
        let url = URL(string: "\(baseURL)/analyze-clothing")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add user_id
        let userId = getUserId()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(userId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add remove_background flag
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"remove_background\"\r\n\r\n".data(using: .utf8)!)
        body.append("true".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("📤 Sending analyze request to \(url) with user_id: \(userId)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📥 Received response: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorMessage)")
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            let analysis = try JSONDecoder().decode(ClothingAnalysis.self, from: data)
            print("✅ Successfully decoded clothing analysis")
            return analysis
        } catch {
            print("❌ Failed to decode response: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON: \(jsonString)")
            }
            throw APIError.decodingError(error)
        }
    }

    /// Claude-powered smart outfit matching (sends all items)
    func getSmartOutfits(
        occasion: String,
        wardrobeItems: [ClothingItem],
        weather: Weather? = nil
    ) async throws -> [(name: String, vibe: String, items: [String], stylingTips: String)] {
        let url = URL(string: "\(baseURL)/style-outfit-smart")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request with all items
        var requestDict: [String: Any] = [
            "occasion": occasion,
            "wardrobe_items": wardrobeItems.map { $0.toDictionary() }
        ]

        if let weather = weather {
            requestDict["weather"] = weather.toDictionary()
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestDict)

        print("🤖 Getting smart Claude-matched outfits...")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let outfitsArray = json["outfits"] as? [[String: Any]] ?? []

        return outfitsArray.map { outfit in
            let items = (outfit["items"] as? [[String: Any]] ?? []).map { $0["id"] as? String ?? "" }
            return (
                name: outfit["name"] as? String ?? "Outfit",
                vibe: outfit["vibe"] as? String ?? "",
                items: items,
                stylingTips: outfit["styling_tips"] as? String ?? ""
            )
        }
    }

    /// Get multiple outfit styling recipes from backend (Claude)
    func getStyleRecipes(
        occasion: String,
        weather: Weather? = nil
    ) async throws -> [StyleRecipe] {
        let url = URL(string: "\(baseURL)/style-recipe")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request
        var requestDict: [String: Any] = [
            "occasion": occasion
        ]

        if let weather = weather {
            requestDict["weather"] = [
                "temperature": weather.temperature,
                "condition": weather.condition
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestDict)

        print("🎨 Getting style recipe for \(occasion)...")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let outfitsArray = json["outfits"] as? [[String: Any]] ?? []

        return outfitsArray.map { outfitData in
            StyleRecipe(
                name: outfitData["name"] as? String ?? "Outfit",
                vibe: outfitData["vibe"] as? String ?? "",
                occasion: json["occasion"] as? String ?? occasion,
                recipe: outfitData["recipe"] as? [String: String] ?? [:],
                colorPalette: outfitData["color_palette"] as? [String] ?? [],
                stylingTips: outfitData["styling_tips"] as? String ?? "",
                formalityLevel: outfitData["formality_level"] as? String ?? "casual"
            )
        }
    }

    /// Style outfit from user's closet using AI (legacy - sends all items)
    func styleOutfit(
        occasion: String,
        wardrobeItems: [ClothingItem],
        weather: Weather? = nil
    ) async throws -> OutfitSuggestion {
        let url = URL(string: "\(baseURL)/style-outfit")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request
        let userId = getUserId()
        var requestDict: [String: Any] = [
            "user_id": userId,
            "occasion": occasion,
            "wardrobe_items": wardrobeItems.map { item in
                [
                    "id": item.id.uuidString,
                    "type": item.type,
                    "color": item.color,
                    "pattern": item.pattern,
                    "style": item.style,
                    "season": item.season,
                    "pairs_well_with": item.pairsWellWith,
                    "confidence": item.confidence,
                    "extracted_image_url": item.imagePath,
                    "material": item.material as Any,
                    "occasion": item.occasion as Any
                ]
            }
        ]

        if let weather = weather {
            requestDict["weather"] = [
                "temperature": weather.temperature,
                "condition": weather.condition
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestDict)

        print("🎨 Styling outfit for \(occasion)...")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        guard let success = json["success"] as? Bool, success else {
            let message = json["message"] as? String ?? "Unknown error"
            throw APIError.networkError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        }

        let outfitData = json["outfit"] as! [String: Any]
        let items = outfitData["items"] as! [[String: Any]]

        // Convert to OutfitSuggestion
        let outfitItems = items.map { item in
            OutfitSuggestion.OutfitItem(
                id: item["id"] as! String,
                type: item["type"] as! String,
                reasoning: item["role_in_outfit"] as! String
            )
        }

        return OutfitSuggestion(
            occasion: occasion,
            items: outfitItems,
            reasoning: outfitData["why_this_works"] as! String,
            styleTips: outfitData["styling_advice"] as! String,
            weatherTemp: weather?.temperature,
            weatherCondition: weather?.condition
        )
    }

    /// Generate outfit suggestions
    func generateOutfit(
        wardrobeItems: [ClothingItem],
        occasion: String,
        weather: Weather? = nil,
        colorPreference: String? = nil
    ) async throws -> OutfitSuggestion {
        let url = URL(string: "\(baseURL)/generate-outfit")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request dictionary
        var requestDict: [String: Any] = [
            "wardrobe_items": wardrobeItems.map { $0.toDictionary() },
            "occasion": occasion
        ]

        if let weather = weather {
            requestDict["weather"] = weather.toDictionary()
        }

        if let colorPreference = colorPreference {
            requestDict["color_preference"] = colorPreference
        }

        // Convert to JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: requestDict)

        print("📤 Generating outfit for occasion: \(occasion)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        print("✅ Outfit generated successfully")

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(OutfitSuggestion.self, from: data)
    }

    /// Generate virtual try-on image
    func virtualTryOn(
        userImage: UIImage,
        clothingItems: [UIImage],
        styleGuidance: String? = nil
    ) async throws -> UIImage {
        let url = URL(string: "\(baseURL)/virtual-tryon-outfit")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add user_id
        let userId = getUserId()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(userId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add model image
        guard let modelImageData = userImage.jpegData(compressionQuality: 0.8) else {
            throw APIError.imageConversionFailed
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model_image\"; filename=\"model.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(modelImageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add each clothing item separately (up to 5 items)
        for (index, clothingImage) in clothingItems.prefix(5).enumerated() {
            guard let clothingImageData = clothingImage.jpegData(compressionQuality: 0.8) else {
                throw APIError.imageConversionFailed
            }

            let fieldName = "clothing_image_\(index + 1)"
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"clothing\(index + 1).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(clothingImageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("📤 Generating virtual try-on with \(clothingItems.count) separate clothing items...")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📥 Received response: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorMessage)")
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        // Parse JSON response
        do {
            let jsonResponse = try JSONDecoder().decode(VirtualTryOnResponse.self, from: data)

            // Try to get image from base64 first
            if let base64String = jsonResponse.try_on_image_base64,
               let imageData = Data(base64Encoded: base64String),
               let resultImage = UIImage(data: imageData) {
                print("✅ Virtual try-on generated successfully from base64")
                return resultImage
            }

            // Fallback to downloading from URL if available
            if let imageUrlString = jsonResponse.try_on_image_url,
               let imageUrl = URL(string: imageUrlString) {
                print("📥 Downloading result from Tigris URL...")
                let (imageData, _) = try await session.data(from: imageUrl)
                guard let resultImage = UIImage(data: imageData) else {
                    throw APIError.invalidResponse
                }
                print("✅ Virtual try-on downloaded successfully")
                return resultImage
            }

            throw APIError.invalidResponse
        } catch {
            print("❌ Failed to parse virtual try-on response: \(error)")
            throw APIError.decodingError(error)
        }
    }

    /// Backup encrypted wardrobe to Tigris
    func backupWardrobe(userId: String, encryptedData: Data) async throws -> BackupResponse {
        let url = URL(string: "\(baseURL)/backup-wardrobe")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encryptedBase64 = encryptedData.base64EncodedString()

        let requestBody = BackupRequest(
            user_id: userId,
            encrypted_data: encryptedBase64,
            metadata: nil
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        print("📤 Backing up wardrobe...")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        print("✅ Wardrobe backed up successfully")

        return try JSONDecoder().decode(BackupResponse.self, from: data)
    }

    /// Get list of backups for a user
    func listBackups(userId: String) async throws -> [BackupInfo] {
        let url = URL(string: "\(baseURL)/list-backups/\(userId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let result = try JSONDecoder().decode(BackupListResponse.self, from: data)
        return result.backups
    }

    /// Fetch and restore encrypted wardrobe backup from Tigris
    func fetchBackup(userId: String) async throws -> Data {
        // First, get list of backups
        let backups = try await listBackups(userId: userId)

        guard let latestBackup = backups.first else {
            throw APIError.serverError(statusCode: 404)
        }

        // Download the backup file from presigned URL
        guard let backupURL = URL(string: latestBackup.url) else {
            throw APIError.invalidResponse
        }

        print("📥 Fetching backup from: \(backupURL)")

        let (data, response) = try await session.data(from: backupURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        print("✅ Backup fetched successfully (\(data.count) bytes)")

        return data
    }

    /// Check API health
    func checkHealth() async throws -> HealthResponse {
        let url = URL(string: "\(baseURL)/health")!

        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }
}

// MARK: - Request Models

struct VirtualTryOnRequest: Codable {
    let user_image_base64: String
    let clothing_items_base64: [String]
    let style_guidance: String?
}

struct VirtualTryOnResponse: Codable {
    let success: Bool
    let message: String
    let try_on_image_url: String?
    let try_on_image_base64: String?
    let timestamp: String
}

struct BackupRequest: Codable {
    let user_id: String
    let encrypted_data: String
    let metadata: [String: String]?
}

// MARK: - Response Models

struct ClothingAnalysis: Codable {
    let type: String
    let color: String
    let pattern: String
    let style: String
    let season: [String]
    let pairs_well_with: [String]
    let confidence: Double
    let material: String?
    let occasion: [String]?
    let care_instructions: String?
    let all_items: [ClothingAnalysis]?  // For multiple items detected
    let item_count: Int?  // Number of items detected
    let extracted_image: String?  // Base64 encoded extracted/cleaned image
    let original_image_url: String?  // Tigris URL for original image
    let extracted_image_url: String?  // Tigris URL for extracted image
    let background_was_removed: Bool?  // Whether background removal was applied

    enum CodingKeys: String, CodingKey {
        case type, color, pattern, style, season, confidence, material, occasion
        case pairs_well_with
        case care_instructions
        case all_items
        case item_count
        case extracted_image
        case original_image_url
        case extracted_image_url
        case background_was_removed
    }
}

struct BackupResponse: Codable {
    let status: String
    let backup_url: String
    let timestamp: String
}

struct BackupInfo: Codable, Identifiable {
    let key: String
    let size: Int
    let last_modified: String
    let url: String

    var id: String { key }
}

struct BackupListResponse: Codable {
    let user_id: String
    let backups: [BackupInfo]
}

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let services: [String: ServiceStatus]

    struct ServiceStatus: Codable {
        let enabled: Bool
        let model: String?
    }
}

// MARK: - Style Recipe Model

struct StyleRecipe: Identifiable {
    let id = UUID()
    let name: String              // "Classic Look", "Modern Edge"
    let vibe: String              // "Timeless and polished"
    let occasion: String
    let recipe: [String: String]  // category -> criteria
    let colorPalette: [String]
    let stylingTips: String
    let formalityLevel: String
}

// MARK: - Weather Model

struct Weather: Codable {
    let temperature: Double
    let condition: String

    func toDictionary() -> [String: Any] {
        return [
            "temperature": temperature,
            "condition": condition
        ]
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(Error)
    case imageConversionFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error (status code: \(statusCode))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
