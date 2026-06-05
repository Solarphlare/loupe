//
//  MusicLibraryProvider.swift
//  Loupe
//
//  Counts items in the local music library and surfaces the user's top
//  genres and artists. Reveals taste data that ad and recommendation
//  SDKs pay handsomely for, all behind a single iOS prompt.
//

import Foundation

#if os(iOS)
@preconcurrency import MediaPlayer
import StoreKit

@MainActor
struct MusicLibraryProvider: SignalProvider {
    let category: SignalCategory = .musicLibrary
    let center: PermissionCenter

    func collect() async -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []

        let songs = MPMediaQuery.songs().items ?? []
        let albums = MPMediaQuery.albums().collections ?? []
        let playlists = MPMediaQuery.playlists().collections ?? []
        let artists = MPMediaQuery.artists().collections ?? []

        signals.append(
            .make(
                "songCount",
                category: category,
                name: String(localized: "Songs", comment: "Signal card name in the Music category — total songs in the local music library."),
                value: String(songs.count),
                rationale: String(localized: "Total songs in the local music library.", comment: "Signal card rationale beneath the Songs value.")))
        signals.append(
            .make(
                "albumCount",
                category: category,
                name: String(localized: "Albums", comment: "Signal card name in the Music category — total albums represented in the library."),
                value: String(albums.count),
                rationale: String(localized: "Total albums represented in the library.", comment: "Signal card rationale beneath the Albums value.")))
        signals.append(
            .make(
                "playlistCount",
                category: category,
                name: String(localized: "Playlists", comment: "Signal card name in the Music category — total playlists (smart and user-made)."),
                value: String(playlists.count),
                rationale: String(localized: "Total playlists, including smart and user-made.", comment: "Signal card rationale beneath the Playlists value.")))
        signals.append(
            .make(
                "artistCount",
                category: category,
                name: String(localized: "Artists", comment: "Signal card name in the Music category — distinct artist count."),
                value: String(artists.count),
                rationale: String(localized: "Distinct artist count.", comment: "Signal card rationale beneath the Artists value.")))

        let topGenres = topItems(in: songs, key: { $0.genre }, limit: 3)
        let genreEntries = topGenres.map { SignalEntry(label: $0.name, value: String($0.count)) }
        signals.append(
            .make(
                "topGenres",
                category: category,
                name: String(localized: "Top genres", comment: "Signal card name in the Music category — most common genres in the library by song count."),
                value: topGenres.isEmpty
                    ? "(none)"
                    : topGenres.map { "\($0.name) (\($0.count))" }.joined(separator: ", "),
                rationale: String(localized: "Most common genres by song count.", comment: "Signal card rationale beneath the Top genres value."),
                displayHint: genreEntries.isEmpty ? .plain : .keyValue,
                entries: genreEntries.isEmpty ? nil : genreEntries))

        let topArtists = topItems(in: songs, key: { $0.artist }, limit: 3)
        let artistEntries = topArtists.map { SignalEntry(label: $0.name, value: String($0.count)) }
        signals.append(
            .make(
                "topArtists",
                category: category,
                name: String(localized: "Top artists", comment: "Signal card name in the Music category — artists with the most songs in the library."),
                value: topArtists.isEmpty
                    ? "(none)"
                    : topArtists.map { "\($0.name) (\($0.count))" }.joined(separator: ", "),
                rationale: String(localized: "Artists with the most songs in your library.", comment: "Signal card rationale beneath the Top artists value."),
                displayHint: artistEntries.isEmpty ? .plain : .keyValue,
                entries: artistEntries.isEmpty ? nil : artistEntries))

        let recentCutoff = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let recentCount = songs.reduce(0) { count, item in
            (item.dateAdded as Date?).map { $0 >= recentCutoff ? count + 1 : count } ?? count
        }
        signals.append(
            .make(
                "recentlyAdded",
                category: category,
                name: String(localized: "Added in last 30 days", comment: "Signal card name in the Music category — number of songs added in the last 30 days."),
                value: String(recentCount),
                rationale: String(localized: "Songs added in the last 30 days.", comment: "Signal card rationale beneath the Added in last 30 days value.")))

        if let subscription = await appleMusicCapabilities() {
            signals.append(subscription)
        }

        return signals
    }

    // MARK: - Helpers

    private func topItems(
        in items: [MPMediaItem],
        key: (MPMediaItem) -> String?,
        limit: Int
    ) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for item in items {
            guard let name = key(item), !name.isEmpty else { continue }
            counts[name, default: 0] += 1
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    private func appleMusicCapabilities() async -> FingerprintSignal? {
        let controller = SKCloudServiceController()
        let capabilities: SKCloudServiceCapability? = await withCheckedContinuation { continuation in
            controller.requestCapabilities { caps, _ in
                continuation.resume(returning: caps)
            }
        }
        guard let capabilities else { return nil }
        var flags: [String] = []
        if capabilities.contains(.musicCatalogPlayback) { flags.append(String(localized: "catalog playback", comment: "Apple Music capability label joined into the Apple Music capabilities value. Matches Apple's SKCloudServiceCapability.musicCatalogPlayback flag.")) }
        if capabilities.contains(.musicCatalogSubscriptionEligible) { flags.append(String(localized: "subscription eligible", comment: "Apple Music capability label joined into the Apple Music capabilities value. Matches Apple's SKCloudServiceCapability.musicCatalogSubscriptionEligible flag.")) }
        if capabilities.contains(.addToCloudMusicLibrary) { flags.append(String(localized: "iCloud Music Library", comment: "Apple Music capability label joined into the Apple Music capabilities value. Matches Apple's SKCloudServiceCapability.addToCloudMusicLibrary flag.")) }
        let summary = flags.isEmpty ? String(localized: "none", comment: "Placeholder shown in the Apple Music capabilities value when none of the capability flags are set.") : flags.joined(separator: ", ")
        return .make(
            "appleMusic",
            category: category,
            name: String(localized: "Apple Music capabilities", comment: "Signal card name in the Music category — flags from SKCloudServiceController.requestCapabilities."),
            value: summary,
            rationale: String(localized: "Your Apple Music subscription and iCloud Music Library state.", comment: "Signal card rationale beneath the Apple Music capabilities value."))
    }
}

#else // macOS

@MainActor
struct MusicLibraryProvider: SignalProvider {
    let category: SignalCategory = .musicLibrary
    let center: PermissionCenter

    func collect() async -> [FingerprintSignal] {
        [
            .make(
                "unavailable",
                category: category,
                name: String(localized: "Music Library", comment: "Signal card name in the Music category — placeholder shown on macOS where MediaPlayer's library APIs are unavailable."),
                value: String(localized: "Not available on macOS", comment: "Placeholder value shown when music library is unavailable on this platform."),
                rationale: String(localized: "MediaPlayer's library APIs are iOS-only.", comment: "Signal card rationale beneath the Music Library placeholder on macOS.")),
        ]
    }
}

#endif
