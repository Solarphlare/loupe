//
//  AppInfoProvider.swift
//  Loupe
//
//  Bundle metadata, executable architecture and the install timestamp
//  of this app. The install date is especially interesting because it
//  is the oldest "fresh" date visible to a third-party app.
//

import Foundation

struct AppInfoProvider: SignalProvider {
    let category: SignalCategory = .appInfo

    func collect() async -> [FingerprintSignal] {
        let info = Bundle.main.infoDictionary ?? [:]
        var signals: [FingerprintSignal] = []

        let version = (info["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (info["CFBundleVersion"] as? String) ?? "?"
        let sdk = (info["DTSDKName"] as? String) ?? "?"
        signals.append(
            .make(
                "buildStamp",
                category: category,
                name: String(localized: "Build stamp", comment: "Signal card name in the App & Bundle category — Loupe's own build metadata."),
                value: "\(version) (\(build)) / \(sdk)",
                rationale: String(localized: "This app's build metadata: version, build, and the SDK it was compiled against.", comment: "Signal card rationale beneath the Build stamp value.")))

        if let docs = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
            let created = (try? docs.resourceValues(forKeys: [.creationDateKey]))?.creationDate
        {
            signals.append(
                .make(
                    "installDate",
                    category: category,
                    name: String(localized: "Install date", comment: "Signal card name in the App & Bundle category — when Loupe was installed."),
                    value: ISO8601DateFormatter().string(from: created),
                    rationale: String(localized: "Creation date of the app's Documents folder. Indicates when the app was installed.", comment: "Signal card rationale beneath the Install date value.")))
        }
        return signals
    }
}
