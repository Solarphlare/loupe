//
//  RemindersProvider.swift
//  Loupe
//
//  Counts reminder lists, shows list titles, and counts incomplete
//  reminders. It does not read reminder titles, notes, or URLs.
//

import EventKit

@MainActor
struct RemindersProvider: SignalProvider {
    let category: SignalCategory = .reminders
    let center: PermissionCenter

    func collect() async -> [FingerprintSignal] {
        let store = EKEventStore()
        var signals: [FingerprintSignal] = []

        let lists = store.calendars(for: .reminder)
        signals.append(
            .make(
                "listCount",
                category: category,
                name: String(localized: "Reminder lists", comment: "Signal card name in the Reminders category — number of reminder lists."),
                value: String(lists.count),
                rationale: String(localized: "Number of reminder lists.", comment: "Signal card rationale beneath the Reminder lists value.")))
        signals.append(
            .make(
                "listTitles",
                category: category,
                name: String(localized: "List titles", comment: "Signal card name in the Reminders category — names of reminder lists."),
                value: lists.map(\.title).joined(separator: ", "),
                rationale: String(localized: "Reminder list names.", comment: "Signal card rationale beneath the List titles value.")))

        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil, calendars: lists)
        let count = await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders?.count ?? 0)
            }
        }
        signals.append(
            .make(
                "incomplete",
                category: category,
                name: String(localized: "Incomplete reminders", comment: "Signal card name in the Reminders category — total count of incomplete reminders."),
                value: String(count),
                rationale: String(localized: "Total incomplete reminders. Individual titles are not accessed.", comment: "Signal card rationale beneath the Incomplete reminders value.")))
        return signals
    }
}
