//
//  CalendarProvider.swift
//  Loupe
//
//  EKEventStore reports the set of calendars, their sources, and a
//  rolling-year event count. We never read event contents.
//

import EventKit
import Foundation

@MainActor
struct CalendarProvider: SignalProvider {
    let category: SignalCategory = .calendar
    let center: PermissionCenter

    func collect() async -> [FingerprintSignal] {
        let store = EKEventStore()
        var signals: [FingerprintSignal] = []

        let calendars = store.calendars(for: .event)
        signals.append(
            .make(
                "calendarCount",
                category: category,
                name: String(localized: "Calendar count", comment: "Signal card name in the Calendar category — total number of calendars across all accounts."),
                value: String(calendars.count),
                rationale: String(localized: "Total calendars across all your accounts (iCloud, Exchange, Google, subscribed).", comment: "Signal card rationale beneath the Calendar count value.")))

        let sources = Set(calendars.map { $0.source.title })
        signals.append(
            .make(
                "sourceCount",
                category: category,
                name: String(localized: "Source count", comment: "Signal card name in the Calendar category — number of distinct calendar providers (iCloud, Gmail, Exchange, etc.)."),
                value: String(sources.count),
                rationale: String(localized: "Distinct calendar providers (e.g., iCloud, Gmail, Exchange).", comment: "Signal card rationale beneath the Source count value.")))
        let sortedSources = sources.sorted()
        signals.append(
            .make(
                "sources",
                category: category,
                name: String(localized: "Sources", comment: "Signal card name in the Calendar category — list of calendar provider names."),
                value: sortedSources.joined(separator: ", "),
                rationale: String(localized: "Calendar provider names.", comment: "Signal card rationale beneath the Sources value."),
                displayHint: sortedSources.isEmpty ? .plain : .tags,
                entries: sortedSources.isEmpty ? nil : sortedSources.map { SignalEntry(label: $0, value: "") }))

        let types = Set(calendars.map { describe($0.type) })
        let sortedTypes = types.sorted()
        signals.append(
            .make(
                "types",
                category: category,
                name: String(localized: "Types", comment: "Signal card name in the Calendar category — list of calendar types (local, CalDAV, Exchange, subscription, birthday)."),
                value: sortedTypes.joined(separator: ", "),
                rationale: String(localized: "Calendar types (local, CalDAV, Exchange, subscription, birthday).", comment: "Signal card rationale beneath the Types value."),
                displayHint: sortedTypes.isEmpty ? .plain : .tags,
                entries: sortedTypes.isEmpty ? nil : sortedTypes.map { SignalEntry(label: $0, value: "") }))

        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let end = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = store.events(matching: predicate)
        signals.append(
            .make(
                "events60d",
                category: category,
                name: String(localized: "Events (±30 days)", comment: "Signal card name in the Calendar category — number of events within a 60-day window centered on today."),
                value: String(events.count),
                rationale: String(localized: "Event count within a 60-day window around today.", comment: "Signal card rationale beneath the Events (±30 days) value.")))
        return signals
    }

    private func describe(_ type: EKCalendarType) -> String {
        switch type {
        case .local: return "local"
        case .calDAV: return "calDAV"
        case .exchange: return "exchange"
        case .subscription: return "subscription"
        case .birthday: return "birthday"
        @unknown default: return "unknown"
        }
    }
}
