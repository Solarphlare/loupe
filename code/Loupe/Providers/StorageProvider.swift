//
//  StorageProvider.swift
//  Loupe
//
//  Total capacity is device-specific, available capacity is user-specific,
//  and the opportunistic vs important API pair leaks how much iCloud
//  eviction headroom the system is willing to free up.
//

import Foundation

struct StorageProvider: SignalProvider {
    let category: SignalCategory = .storage

    func collect() async -> [FingerprintSignal] {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        var signals: [FingerprintSignal] = []

        let keys: [URLResourceKey] = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityForOpportunisticUsageKey,
            .volumeCreationDateKey,
            .volumeUUIDStringKey,
            .volumeNameKey,
            .volumeLocalizedNameKey,
        ]
        guard let values = try? url.resourceValues(forKeys: Set(keys)) else {
            return []
        }
        if let total = values.volumeTotalCapacity {
            signals.append(
                .make(
                    "total",
                    category: category,
                    name: String(localized: "Total capacity", comment: "Signal card name in the Storage category — total disk capacity reported by the volume."),
                    value: formatBytes(Int64(total)),
                    rationale: String(localized: "Total storage on your \(PlatformDevice.localizedModel)", comment: "Signal card rationale beneath the Total capacity value. %@ is the device model name (e.g., iPhone, iPad).")))
        }
        if let available = values.volumeAvailableCapacity {
            signals.append(
                .make(
                    "available",
                    category: category,
                    name: String(localized: "Available capacity", comment: "Signal card name in the Storage category — free space currently available on the volume."),
                    value: formatBytes(Int64(available)),
                    rationale: String(localized: "Free space on your \(PlatformDevice.localizedModel). It changes slowly, so similar values across sessions can be correlated to one another.", comment: "Signal card rationale beneath the Available capacity value. %@ is the device model name. Explains that free space is a near-stable user-specific identifier.")))
        }
        let importantAvail = values.volumeAvailableCapacityForImportantUsage
        let opportunistic = values.volumeAvailableCapacityForOpportunisticUsage
        if importantAvail != nil || opportunistic != nil {
            let imp = importantAvail.map { formatBytes($0) } ?? "?"
            let opp = opportunistic.map { formatBytes($0) } ?? "?"
            signals.append(
                .make(
                    "reclaimable",
                    category: category,
                    name: String(localized: "Reclaimable capacity", comment: "Signal card name in the Storage category — capacity available if the system reclaims purgeable caches."),
                    value: "important: \(imp) / opportunistic: \(opp)",
                    rationale: String(localized: "These APIs report free space including purgeable caches. The gap between them shows how much space the system could free up if asked.", comment: "Signal card rationale beneath the Reclaimable capacity value. Explains the Important vs Opportunistic split."),
                    displayHint: .compound,
                    entries: [
                        SignalEntry(label: String(localized: "Important", comment: "Reclaimable-capacity sub-label. Apple's term for free space the system will reclaim only when an app marks the request as important."), value: imp),
                        SignalEntry(label: String(localized: "Opportunistic", comment: "Reclaimable-capacity sub-label. Apple's term for free space the system will reclaim eagerly, e.g. by evicting iCloud caches."), value: opp),
                    ]))
        }
        if let created = values.volumeCreationDate {
            signals.append(
                .make(
                    "created",
                    category: category,
                    name: String(localized: "Volume creation date", comment: "Signal card name in the Storage category — date when the volume was created."),
                    value: ISO8601DateFormatter().string(from: created),
                    rationale: String(localized: "When your \(PlatformDevice.localizedModel) was first set up or last erased.", comment: "Signal card rationale beneath the Volume creation date value. %@ is the device model name.")))
        }
        if let uuid = values.volumeUUIDString {
            signals.append(
                .make(
                    "uuid",
                    category: category,
                    name: String(localized: "Volume UUID", comment: "Signal card name in the Storage category — UUID assigned to the volume."),
                    value: uuid,
                    rationale: String(localized: "Volume identifier. Appears to be identical across all iOS and iPadOS devices, so on its own it can't single you out.", comment: "Signal card rationale beneath the Volume UUID value. Notes that the value is shared across iOS and iPadOS devices.")))
        }
        let name = values.volumeName
        let localized = values.volumeLocalizedName
        if name != nil || localized != nil {
            let display: String
            if let name, let localized, name != localized {
                display = "\(name) (localized: \(localized))"
            } else {
                display = name ?? localized ?? ""
            }
            signals.append(
                .make(
                    "name",
                    category: category,
                    name: String(localized: "Volume name", comment: "Signal card name in the Storage category — human-readable volume name."),
                    value: display,
                    rationale: String(localized: "Appears to be identical across all iOS and iPadOS devices.", comment: "Signal card rationale beneath the Volume name value. Notes that the value is shared across iOS and iPadOS devices.")))
        }
        return signals
    }

    private func formatBytes(_ value: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        f.includesActualByteCount = true
        return f.string(fromByteCount: value)
    }
}
