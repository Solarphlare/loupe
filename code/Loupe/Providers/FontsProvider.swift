//
//  FontsProvider.swift
//  Loupe
//
//  Font family names reveal every installed typeface. Vanilla devices
//  are identical; the interesting signal shows up when a user has added
//  fonts via Configuration Profiles, iCloud Fonts, or apps that install
//  custom typefaces.
//

import Foundation

struct FontsProvider: SignalProvider {
    let category: SignalCategory = .fonts

    func collect() async -> [FingerprintSignal] {
        let families = PlatformFont.familyNames.sorted()
        var signals: [FingerprintSignal] = []
        signals.append(
            .make(
                "familyCount",
                category: category,
                name: String(localized: "Installed font families", comment: "Signal card name in the Fonts category — count of installed font families."),
                value: String(families.count),
                rationale: String(localized: "Number of font families installed. A count above the system default usually means you've added custom fonts.", comment: "Signal card rationale beneath the Installed font families value.")))
        signals.append(
            .make(
                "familiesAll",
                category: category,
                name: String(localized: "All families", comment: "Signal card name in the Fonts category — full list of installed font family names."),
                value: families.joined(separator: ", "),
                rationale: String(localized: "Full list of available font families.", comment: "Signal card rationale beneath the All families value."),
                displayHint: .tags,
                entries: families.map { SignalEntry(label: $0, value: "") }))
        return signals
    }
}
