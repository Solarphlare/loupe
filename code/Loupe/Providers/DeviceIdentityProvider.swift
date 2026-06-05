//
//  DeviceIdentityProvider.swift
//  Loupe
//
//  The original fingerprint. `identifierForVendor` alone isn't
//  per-install, and the raw hardware strings pin down the exact SoC
//  variant every device was shipped with.
//
//  Platform note: on iOS, `hw.machine` returns the model identifier
//  (e.g., "iPhone16,1") and `hw.model` returns the board code. On
//  macOS it's reversed: `hw.machine` returns the CPU architecture
//  ("arm64") and `hw.model` returns the model identifier
//  (e.g., "MacBookPro18,2"). `modelIdentifier` abstracts this.
//

import Foundation

struct DeviceIdentityProvider: SignalProvider {
    let category: SignalCategory = .deviceIdentity

    func collect() async -> [FingerprintSignal] {
        let uname = SysctlHelper.uname()
        var signals: [FingerprintSignal] = []

        signals.append(
            .make(
                "idfv",
                category: category,
                name: String(localized: "identifierForVendor", comment: "Signal card name in the Device Identity category — Apple's UIDevice.identifierForVendor UUID."),
                value: PlatformDevice.identifierForVendor?.uuidString ?? "unavailable",
                rationale:
                    String(localized: "Stays the same across every app from the same developer, until you uninstall all of them.", comment: "Signal card rationale beneath the identifierForVendor value.")
            ))
        signals.append(
            .make(
                "name",
                category: category,
                name: String(localized: "Device name", comment: "Signal card name in the Device Identity category — UIDevice.name (the device's display name)."),
                value: PlatformDevice.name,
                rationale:
                    String(localized: "Usually a generic product name on iOS and iPadOS 16+. A handful of Apple-approved apps (through entitlements) can still see the name you set.", comment: "Signal card rationale beneath the Device name value.")
            ))
        if let hostname = SysctlHelper.string("kern.hostname") {
            signals.append(
                .make(
                    "kern.hostname",
                    category: category,
                    name: String(localized: "kern.hostname", comment: "Signal card name in the Device Identity category — the kern.hostname sysctl value (DNS hostname)."),
                    value: hostname,
                    rationale:
                        String(localized: "The DNS hostname. On some setups, it matches the name you've given your \(PlatformDevice.localizedModel).", comment: "Signal card rationale beneath the kern.hostname value. %@ is the device model name (e.g., iPhone, iPad).")
                ))
        }
        signals.append(
            .make(
                "systemVersion",
                category: category,
                name: String(localized: "systemVersion", comment: "Signal card name in the Device Identity category — UIDevice.systemVersion (OS version string)."),
                value: PlatformDevice.systemVersion,
                rationale:
                    String(localized: "Your specific \(PlatformDevice.systemName) version.", comment: "Signal card rationale beneath the systemVersion value. %@ is the OS name (iOS, iPadOS, macOS).")
            ))

        let modelID = SysctlHelper.modelIdentifier()
        if let modelID {
            #if os(iOS)
            let board = SysctlHelper.string("hw.model")
            let value = board.map { "\(modelID) (board \($0))" } ?? modelID
            #else
            let machine = uname["machine"]
            let value = machine.map { "\(modelID) (arch \($0))" } ?? modelID
            #endif
            signals.append(
                .make(
                    "hw.machine",
                    category: category,
                    name: String(localized: "Model identifier", comment: "Signal card name in the Device Identity category — Apple's internal hardware model identifier (e.g., iPhone16,1, MacBookPro18,2)."),
                    value: value,
                    rationale:
                        String(localized: "Apple's internal hardware identifier (e.g., iPhone16,1 or MacBookPro18,2).", comment: "Signal card rationale beneath the Model identifier value.")
                ))
        }
        if let cpuType = SysctlHelper.int64("hw.cputype") {
            let sub = SysctlHelper.int64("hw.cpusubtype")
            let value = sub.map { "\(cpuType) / sub \($0)" } ?? String(cpuType)
            signals.append(
                .make(
                    "hw.cputype",
                    category: category,
                    name: String(localized: "hw.cputype", comment: "Signal card name in the Device Identity category — the hw.cputype sysctl value (CPU architecture identifier)."),
                    value: value,
                    rationale:
                        String(localized: "CPU architecture identifiers from the kernel.", comment: "Signal card rationale beneath the hw.cputype value.")
                ))
        }
        return signals
    }
}
