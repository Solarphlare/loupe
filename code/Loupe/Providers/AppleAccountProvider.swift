//
//  AppleAccountProvider.swift
//  Loupe
//
//  Two silently-readable surfaces tied to the logged-in Apple Account:
//  the iCloud ubiquity token (an opaque per-account blob that stays
//  stable across every app on the device until the user signs out) and
//  the App Store storefront country set on that account. No entitlement
//  or user prompt is required for either.
//

import CryptoKit
import Foundation
import StoreKit

struct AppleAccountProvider: SignalProvider {
    let category: SignalCategory = .appleAccount

    func collect() async -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []

        if let token = FileManager.default.ubiquityIdentityToken {
            signals.append(
                .make(
                    "ubiquityToken.hash",
                    category: category,
                    name: String(localized: "iCloud token hash", comment: "Signal card name in the Apple Account category — SHA-256 hash of the iCloud ubiquity identity token."),
                    value: Self.stableHash(of: token),
                    rationale:
                        String(localized: "A hash of the iCloud account token. The token isn't shared between different apps, though for the same app it remains consistent across app installs.", comment: "Signal card rationale beneath the iCloud token hash value.")))
        } else {
            signals.append(
                .make(
                    "ubiquityToken.hash",
                    category: category,
                    name: String(localized: "iCloud token hash", comment: "Signal card name in the Apple Account category — SHA-256 hash of the iCloud ubiquity identity token."),
                    value: "absent",
                    rationale:
                        String(localized: "Usually means you aren't signed in to iCloud, or iCloud Drive is off.", comment: "Signal card rationale beneath the iCloud token hash value when no token was returned.")))
        }

        if let storefront = await Storefront.current {
            signals.append(
                .make(
                    "storefront.country",
                    category: category,
                    name: String(localized: "App Store country", comment: "Signal card name in the Apple Account category — App Store storefront country code."),
                    value: storefront.countryCode,
                    rationale:
                        String(localized: "ISO country code from your App Store account. Pins the account to a country regardless of where the \(PlatformDevice.localizedModel) is right now.", comment: "Signal card rationale beneath the App Store country value. %@ is the device model name (e.g., iPhone, iPad).")))
        } else {
            signals.append(
                .make(
                    "storefront.country",
                    category: category,
                    name: String(localized: "App Store country", comment: "Signal card name in the Apple Account category — App Store storefront country code."),
                    value: "unavailable",
                    rationale:
                        String(localized: "Usually means you aren't signed in to an App Store account.", comment: "Signal card rationale beneath the App Store country value when no storefront was returned.")))
        }

        return signals
    }

    /// Hex-encoded SHA-256 of the archived token, truncated so the raw
    /// identifier never appears on screen.
    private static func stableHash(of token: any NSObjectProtocol) -> String {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: token, requiringSecureCoding: true)
        else {
            return "unhashable"
        }
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex
    }
}
