/**
 * Encryption Service
 *
 * Handles all encryption and decryption of user data using AES-256-GCM.
 * Ensures privacy by encrypting wardrobe data locally before any cloud backup.
 *
 * Security Features:
 * - AES-256-GCM encryption
 * - Secure key storage in iOS Keychain
 * - Random IV (Initialization Vector) for each encryption
 * - Authentication tag for data integrity
 *
 * Privacy: User data never leaves the device unencrypted.
 */

import Foundation
import CryptoKit
import Security

class EncryptionService {
    // MARK: - Singleton

    static let shared = EncryptionService()

    // MARK: - Properties

    private let keychainService = "com.closetscanner.encryption"
    private let keychainAccount = "master-key"

    // MARK: - Initialization

    private init() {
        // Ensure encryption key exists on first use
        // Key will be created lazily when first encryption/decryption is attempted
    }

    // MARK: - Public Methods

    /// Encrypt data using AES-256-GCM
    func encrypt(data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()

        // Create a sealed box with the encrypted data
        let sealedBox = try AES.GCM.seal(data, using: key)

        // Combine nonce + ciphertext + tag for storage
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }

        return combined
    }

    /// Decrypt data using AES-256-GCM
    func decrypt(data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()

        // Create sealed box from combined data
        let sealedBox = try AES.GCM.SealedBox(combined: data)

        // Decrypt
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        return decryptedData
    }

    /// Encrypt a string
    func encrypt(string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        return try encrypt(data: data)
    }

    /// Decrypt to a string
    func decryptToString(data: Data) throws -> String {
        let decryptedData = try decrypt(data: data)

        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }

        return string
    }

    /// Encrypt image data
    func encryptImage(_ image: UIImage, compressionQuality: CGFloat = 0.8) throws -> Data {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw EncryptionError.invalidData
        }
        return try encrypt(data: imageData)
    }

    /// Decrypt image data
    func decryptToImage(data: Data) throws -> UIImage {
        let decryptedData = try decrypt(data: data)

        guard let image = UIImage(data: decryptedData) else {
            throw EncryptionError.invalidData
        }

        return image
    }

    /// Reset encryption key (WARNING: This will make all encrypted data unreadable)
    func resetEncryptionKey() throws {
        try deleteEncryptionKey()
        _ = try getOrCreateEncryptionKey()
    }

    // MARK: - Private Methods

    /// Get existing encryption key or create a new one
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key
        if let existingKey = try? loadEncryptionKey() {
            return existingKey
        }

        // Create new key
        let newKey = SymmetricKey(size: .bits256)
        try saveEncryptionKey(newKey)

        return newKey
    }

    /// Save encryption key to Keychain
    private func saveEncryptionKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }

    /// Load encryption key from Keychain
    private func loadEncryptionKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw EncryptionError.keychainError(status)
        }

        return SymmetricKey(data: keyData)
    }

    /// Delete encryption key from Keychain
    private func deleteEncryptionKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EncryptionError.keychainError(status)
        }
    }
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidData:
            return "Invalid data format"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - UIImage Extension

import UIKit

extension UIImage {
    /// Convenience method to encrypt this image
    func encrypted(compressionQuality: CGFloat = 0.8) throws -> Data {
        return try EncryptionService.shared.encryptImage(self, compressionQuality: compressionQuality)
    }
}
