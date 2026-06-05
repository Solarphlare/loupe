//
//  KeychainInstallLog.swift
//  Loupe
//
//  Uses the iOS Keychain to persist a log of install timestamps across
//  app deletions. UserDefaults are wiped on uninstall; Keychain entries
//  survive. By comparing the two we detect fresh installs.
//

import Foundation
import Security

struct KeychainInstallLog: Sendable {
    static let shared = KeychainInstallLog()

    private let service = "co.mysk.loupe.installLog"
    private let account = "installDates"
    private let defaultsKey = "KeychainInstallLog.hasRecorded"

    func recordInstallIfNeeded() {
        let alreadyRecorded = UserDefaults.standard.bool(forKey: defaultsKey)
        guard !alreadyRecorded else { return }

        var dates = readDates()
        dates.append(Date())
        writeDates(dates)
        UserDefaults.standard.set(true, forKey: defaultsKey)
    }

    func installDates() -> [Date] {
        readDates()
    }

    // MARK: - Keychain helpers

    private func readDates() -> [Date] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Date].self, from: data)) ?? []
    }

    private func writeDates(_ dates: [Date]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(dates) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let existing = SecItemCopyMatching(query as CFDictionary, nil)
        if existing == errSecSuccess {
            let update: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(query as CFDictionary, update as CFDictionary)
        } else {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(add as CFDictionary, nil)
        }
    }
}
