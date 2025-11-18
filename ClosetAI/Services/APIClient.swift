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

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("📤 Sending analyze request to \(url)")

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
        let url = URL(string: "\(baseURL)/virtual-tryon")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert images to base64
        guard let userImageData = userImage.jpegData(compressionQuality: 0.8) else {
            throw APIError.imageConversionFailed
        }
        let userBase64 = userImageData.base64EncodedString()

        let clothingBase64 = try clothingItems.map { image -> String in
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                throw APIError.imageConversionFailed
            }
            return data.base64EncodedString()
        }

        // Prepare request body
        let requestBody = VirtualTryOnRequest(
            user_image_base64: userBase64,
            clothing_items_base64: clothingBase64,
            style_guidance: styleGuidance
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        print("📤 Generating virtual try-on...")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let resultImage = UIImage(data: data) else {
            throw APIError.invalidResponse
        }

        print("✅ Virtual try-on generated")

        return resultImage
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

    enum CodingKeys: String, CodingKey {
        case type, color, pattern, style, season, confidence, material, occasion
        case pairs_well_with
        case care_instructions
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
