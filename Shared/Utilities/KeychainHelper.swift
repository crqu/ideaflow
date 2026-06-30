import Foundation
import Security

enum KeychainError: Error, Sendable {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case unexpectedData
    case notFound
}

enum KeychainHelper {
    private static let service = "com.ideaflow.api"
    private static let account = "claude-api-key"

    static func saveApiKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }

        try? deleteApiKey()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func getApiKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let key = String(data: data, encoding: .utf8) else {
                throw KeychainError.unexpectedData
            }
            return key
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.notFound
        }
    }

    static func deleteApiKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
