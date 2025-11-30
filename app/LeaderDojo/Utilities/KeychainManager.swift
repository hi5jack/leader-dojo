import Foundation
import Security

/// Manages secure storage of sensitive data like API keys in the Keychain
/// Thread-safe: Keychain APIs are inherently thread-safe
final class KeychainManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = KeychainManager()
    
    private let service = "com.joinleaderdojo.app"
    
    private init() {}
    
    // MARK: - Keys
    
    enum Key: String, Sendable {
        case openAIAPIKey = "openai_api_key"
    }
    
    // MARK: - Public Methods
    
    /// Save a string value to the Keychain
    nonisolated func save(_ value: String, for key: Key) throws {
        let data = Data(value.utf8)
        
        // Delete any existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            // Ensure we also match synchronizable items
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            // Store in iCloud Keychain when available
            kSecAttrSynchronizable as String: kCFBooleanTrue as Any
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        // If the item somehow already exists, fall back to an update
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key.rawValue,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Retrieve a string value from the Keychain
    nonisolated func retrieve(for key: Key) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            // Match both local and synchronizable items
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return value
    }
    
    /// Delete a value from the Keychain
    nonisolated func delete(for key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Check if a key exists in the Keychain
    nonisolated func exists(for key: Key) -> Bool {
        do {
            return try retrieve(for: key) != nil
        } catch {
            return false
        }
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case unhandledError(status: OSStatus)
    case unexpectedData
    
    var errorDescription: String? {
        switch self {
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        case .unexpectedData:
            return "Unexpected data format in Keychain"
        }
    }
}

