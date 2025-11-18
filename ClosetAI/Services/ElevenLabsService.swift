import Foundation
import AVFoundation

// MARK: - Models

struct ElevenLabsVoice: Codable, Identifiable, Equatable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "voice_id"
        case name
    }
}

private struct ElevenLabsVoicesResponse: Codable {
    let voices: [ElevenLabsVoice]
}

// MARK: - Errors

enum ElevenLabsTTSError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case badResponse(status: Int)
    case apiError(message: String, status: Int)
    case emptyAudio

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Missing ElevenLabs API key"
        case .invalidURL: return "Invalid ElevenLabs API URL"
        case .badResponse(let status): return "ElevenLabs API error (status \(status))"
        case .apiError(let message, let status): return "ElevenLabs API error (status \(status)): \(message)"
        case .emptyAudio: return "No audio returned by ElevenLabs"
        }
    }
}

// MARK: - API Helper

private struct ElevenLabsAPI {
    let apiKey: String
    private let baseURL = URL(string: "https://api.elevenlabs.io")!

    private func url(path: String, query: [URLQueryItem]? = nil) -> URL? {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if let query, !query.isEmpty { comps?.queryItems = query }
        return comps?.url
    }

    func get(path: String, query: [URLQueryItem]? = nil) async throws -> Data {
        guard let u = url(path: path, query: query) else { throw ElevenLabsTTSError.invalidURL }
        var req = URLRequest(url: u)
        req.httpMethod = "GET"
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard 200..<300 ~= status else {
            let msg = extractAPIErrorMessage(from: data) ?? "Unknown error"
            throw ElevenLabsTTSError.apiError(message: msg, status: status)
        }
        return data
    }

    func postJSON<B: Encodable>(path: String, query: [URLQueryItem]? = nil, body: B) async throws -> Data {
        guard let u = url(path: path, query: query) else { throw ElevenLabsTTSError.invalidURL }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let httpBody = try JSONEncoder().encode(body)
        req.httpBody = httpBody
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard 200..<300 ~= status else {
            let msg = extractAPIErrorMessage(from: data) ?? "Unknown error"
            throw ElevenLabsTTSError.apiError(message: msg, status: status)
        }
        return data
    }

    private func extractAPIErrorMessage(from data: Data) -> String? {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let detail = obj["detail"] as? String { return detail }
            if let error = obj["error"] as? [String: Any], let message = error["message"] as? String { return message }
            if let message = obj["message"] as? String { return message }
        }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - TTS Service

final class ElevenLabsTTS {
    static let shared = ElevenLabsTTS()

    private init() {}

    private var voicesCache: [ElevenLabsVoice]? = nil

    func listVoices(apiKey: String) async throws -> [ElevenLabsVoice] {
        if let cached = voicesCache, !cached.isEmpty { return cached }
        let api = ElevenLabsAPI(apiKey: apiKey)
        let data = try await api.get(path: "/v1/voices")
        let decoded = try JSONDecoder().decode(ElevenLabsVoicesResponse.self, from: data)
        voicesCache = decoded.voices
        return decoded.voices
    }

    func synthesize(
        text: String,
        voiceId: String,
        apiKey: String,
        modelId: String? = nil
    ) async throws -> Data {
        let api = ElevenLabsAPI(apiKey: apiKey)

        struct Body: Encodable {
            let text: String
            let model_id: String
            let voice_settings: VoiceSettings
        }

        struct VoiceSettings: Encodable {
            let stability: Double
            let similarity_boost: Double
            let style: Double
            let use_speaker_boost: Bool
        }

        let body = Body(
            text: text,
            model_id: modelId ?? "eleven_turbo_v2_5",
            voice_settings: VoiceSettings(
                stability: 0.5,
                similarity_boost: 0.75,
                style: 0.2,
                use_speaker_boost: true
            )
        )

        let query = [URLQueryItem(name: "output_format", value: "mp3_44100_192")]
        let data = try await api.postJSON(path: "/v1/text-to-speech/\(voiceId)", query: query, body: body)

        guard !data.isEmpty else { throw ElevenLabsTTSError.emptyAudio }
        return data
    }
}
