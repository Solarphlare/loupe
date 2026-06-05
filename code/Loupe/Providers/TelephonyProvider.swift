//
//  TelephonyProvider.swift
//  Loupe
//
//  CoreTelephony still works: serviceCurrentRadioAccessTechnology gives
//  a per-SIM radio tech map, and on iOS 16+ the carrier name itself is
//  redacted to "--" but the SIM count and radio tech remain.
//

import Foundation

#if os(iOS)
import CoreTelephony
#endif

struct TelephonyProvider: SignalProvider {
    let category: SignalCategory = .telephony

    func collect() async -> [FingerprintSignal] {
        #if os(iOS)
        let info = CTTelephonyNetworkInfo()
        var signals: [FingerprintSignal] = []

        if let radio = info.serviceCurrentRadioAccessTechnology {
            signals.append(
                .make(
                    "simCount",
                    category: category,
                    name: String(localized: "Active services", comment: "Signal card name in the Telephony category — number of active cellular services (e.g., dual SIM)."),
                    value: String(radio.count),
                    rationale: String(localized: "Number of active cellular services (e.g., dual SIM).", comment: "Signal card rationale beneath the Active services value.")))
            for (index, entry) in radio.sorted(by: { $0.key < $1.key }).enumerated() {
                signals.append(
                    .make(
                        "rat.\(index)",
                        category: category,
                        name: String(localized: "Radio tech [\(entry.key.prefix(6))…]", comment: "Signal card name in the Telephony category — radio access technology for one SIM. %@ is the first six characters of the CTTelephonyNetworkInfo service identifier."),
                        value: describe(entry.value),
                        rationale: String(localized: "Radio access technology (e.g., LTE, 5G) for this service.", comment: "Signal card rationale beneath each per-service Radio tech value.")))
            }
        } else {
            signals.append(
                .make(
                    "simCount",
                    category: category,
                    name: String(localized: "Active services", comment: "Signal card name in the Telephony category — number of active cellular services (e.g., dual SIM)."),
                    value: "0",
                    rationale: String(localized: "No active cellular subscription detected.", comment: "Signal card rationale beneath the Active services value when no SIM was detected.")))
        }
        return signals
        #else
        return [
            .make(
                "unavailable",
                category: category,
                name: String(localized: "Telephony", comment: "Signal card name in the Telephony category — placeholder shown on macOS where CoreTelephony is unavailable."),
                value: String(localized: "Not available on macOS", comment: "Placeholder value shown when telephony is unavailable on this platform."),
                rationale: String(localized: "CoreTelephony is an iOS-only framework.", comment: "Signal card rationale beneath the Telephony placeholder on macOS."))
        ]
        #endif
    }

    #if os(iOS)
    private func describe(_ rat: String) -> String {
        if rat.hasPrefix("CTRadioAccessTechnology") {
            return String(rat.dropFirst("CTRadioAccessTechnology".count))
        }
        return rat
    }
    #endif
}
