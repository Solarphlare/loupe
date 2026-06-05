//
//  PasteboardProvider.swift
//  Loupe
//
//  iOS 14+ shows the "pasted from" banner when an app actually reads
//  pasteboard *content*. The *shape* properties (`hasStrings`,
//  `hasURLs` etc.) and `changeCount` are silent, so they make an ideal
//  passive-yet-advanced signal.
//

import Foundation

struct PasteboardProvider: SignalProvider {
    let category: SignalCategory = .pasteboard

    func collect() async -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []

        signals.append(
            .make(
                "changeCount",
                category: category,
                name: String(localized: "changeCount", comment: "Signal card name in the Pasteboard category — UIPasteboard.changeCount."),
                value: String(PlatformPasteboard.changeCount),
                rationale:
                    String(localized: "Increments each time the pasteboard changes. The same counter is visible to every app.", comment: "Signal card rationale beneath the changeCount value.")))
        signals.append(
            .make(
                "hasStrings",
                category: category,
                name: String(localized: "hasStrings", comment: "Signal card name in the Pasteboard category — UIPasteboard.hasStrings."),
                value: String(PlatformPasteboard.hasStrings),
                rationale:
                    String(localized: "Whether the pasteboard contains text. Readable without triggering the \"pasted from\" banner.", comment: "Signal card rationale beneath the hasStrings value.")))
        signals.append(
            .make(
                "hasURLs",
                category: category,
                name: String(localized: "hasURLs", comment: "Signal card name in the Pasteboard category — UIPasteboard.hasURLs."),
                value: String(PlatformPasteboard.hasURLs),
                rationale: String(localized: "Whether the pasteboard contains a URL.", comment: "Signal card rationale beneath the hasURLs value.")))
        signals.append(
            .make(
                "hasImages",
                category: category,
                name: String(localized: "hasImages", comment: "Signal card name in the Pasteboard category — UIPasteboard.hasImages."),
                value: String(PlatformPasteboard.hasImages),
                rationale: String(localized: "Whether the pasteboard contains an image.", comment: "Signal card rationale beneath the hasImages value.")))
        signals.append(
            .make(
                "hasColors",
                category: category,
                name: String(localized: "hasColors", comment: "Signal card name in the Pasteboard category — UIPasteboard.hasColors."),
                value: String(PlatformPasteboard.hasColors),
                rationale: String(localized: "Whether the pasteboard contains a color value.", comment: "Signal card rationale beneath the hasColors value.")))
        signals.append(
            .make(
                "numberOfItems",
                category: category,
                name: String(localized: "numberOfItems", comment: "Signal card name in the Pasteboard category — UIPasteboard.numberOfItems."),
                value: String(PlatformPasteboard.numberOfItems),
                rationale: String(localized: "Number of items on the pasteboard.", comment: "Signal card rationale beneath the numberOfItems value.")))
        return signals
    }
}
