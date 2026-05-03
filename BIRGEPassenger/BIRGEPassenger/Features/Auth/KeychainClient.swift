//
//  KeychainClient.swift
//  BIRGEPassenger
//
//  Created by Арсен Абдухалық on 22.04.2026.
//

import ComposableArchitecture
import Foundation
import Security

// MARK: - KeychainClient

struct KeychainClient: Sendable {
    var save: @Sendable (String, String) throws -> Void
    var load: @Sendable (String) throws -> String?
    var delete: @Sendable (String) throws -> Void

    enum Keys {
        static let accessToken = "birge_access_token"
        static let refreshToken = "birge.refreshToken"
        static let userID = "birge.userID"
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError, Sendable {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case dataConversionFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            "Keychain save failed: \(status)"
        case .loadFailed(let status):
            "Keychain load failed: \(status)"
        case .deleteFailed(let status):
            "Keychain delete failed: \(status)"
        case .dataConversionFailed:
            "Keychain data conversion failed"
        }
    }
}

// MARK: - DependencyKey

extension KeychainClient: DependencyKey {
    static let liveValue = KeychainClient(
        save: { key, value in
            guard let data = value.data(using: .utf8) else {
                throw KeychainError.dataConversionFailed
            }

            // Delete existing item first to avoid duplicates
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
            ]
            SecItemDelete(deleteQuery as CFDictionary)

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String:
                    kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ]

            let status = SecItemAdd(addQuery as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw KeychainError.saveFailed(status)
            }
        },
        load: { key in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            guard status != errSecItemNotFound else { return nil }
            guard status == errSecSuccess else {
                throw KeychainError.loadFailed(status)
            }

            guard let data = result as? Data,
                  let string = String(data: data, encoding: .utf8)
            else {
                throw KeychainError.dataConversionFailed
            }

            return string
        },
        delete: { key in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
            ]

            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.deleteFailed(status)
            }
        }
    )

    static let testValue: KeychainClient = {
        let storage = LockIsolated<[String: String]>([:])
        return KeychainClient(
            save: { key, value in
                storage.withValue { $0[key] = value }
            },
            load: { key in
                storage.withValue { $0[key] }
            },
            delete: { key in
                storage.withValue { $0[key] = nil }
            }
        )
    }()
}

// MARK: - DependencyValues

extension DependencyValues {
    var keychainClient: KeychainClient {
        get { self[KeychainClient.self] }
        set { self[KeychainClient.self] = newValue }
    }
}
