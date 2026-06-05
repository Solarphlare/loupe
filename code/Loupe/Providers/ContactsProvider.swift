//
//  ContactsProvider.swift
//  Loupe
//
//  Counts contacts, phone/email/address fields, labels, and containers.
//  It does not display names, phone numbers, email addresses, or postal
//  addresses.
//

import Contacts

@MainActor
struct ContactsProvider: SignalProvider {
    let category: SignalCategory = .contacts
    let center: PermissionCenter

    func collect() async -> [FingerprintSignal] {
        let store = CNContactStore()
        var signals: [FingerprintSignal] = []

        let containers = (try? store.containers(matching: nil)) ?? []
        signals.append(
            .make(
                "containerCount",
                category: category,
                name: String(localized: "Container count", comment: "Signal card name in the Contacts category — number of contact sources (e.g., iCloud, local, Exchange)."),
                value: String(containers.count),
                rationale: String(localized: "Number of contact sources (e.g., iCloud, local, Exchange).", comment: "Signal card rationale beneath the Container count value.")))

        let request = CNContactFetchRequest(keysToFetch: [
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
        ])
        var total = 0
        var phones = 0
        var emails = 0
        var postal = 0
        let phoneLabelCounts = PhoneLabelCounter()
        try? store.enumerateContacts(with: request) { contact, _ in
            total += 1
            phones += contact.phoneNumbers.count
            emails += contact.emailAddresses.count
            postal += contact.postalAddresses.count
            for entry in contact.phoneNumbers {
                phoneLabelCounts.increment(entry.label ?? "(unlabeled)")
            }
        }
        signals.append(
            .make(
                "total",
                category: category,
                name: String(localized: "Contact count", comment: "Signal card name in the Contacts category — total number of contacts."),
                value: String(total),
                rationale: String(localized: "Total number of contacts.", comment: "Signal card rationale beneath the Contact count value.")))
        signals.append(
            .make(
                "phoneCount",
                category: category,
                name: String(localized: "Phone number count", comment: "Signal card name in the Contacts category — total phone numbers across all contacts."),
                value: String(phones),
                rationale: String(localized: "Total phone numbers across all contacts.", comment: "Signal card rationale beneath the Phone number count value.")))
        signals.append(
            .make(
                "emailCount",
                category: category,
                name: String(localized: "Email count", comment: "Signal card name in the Contacts category — total email addresses across all contacts."),
                value: String(emails),
                rationale: String(localized: "Total email addresses across all contacts.", comment: "Signal card rationale beneath the Email count value.")))
        signals.append(
            .make(
                "postalCount",
                category: category,
                name: String(localized: "Postal address count", comment: "Signal card name in the Contacts category — total postal addresses across all contacts."),
                value: String(postal),
                rationale: String(localized: "Total postal addresses across all contacts.", comment: "Signal card rationale beneath the Postal address count value.")))
        let labelSummary = phoneLabelCounts.summary()
        let labelEntries = phoneLabelCounts.entries()
        signals.append(
            .make(
                "phoneLabels",
                category: category,
                name: String(localized: "Phone number labels", comment: "Signal card name in the Contacts category — counts of phone-number labels used across all contacts."),
                value: labelSummary.isEmpty ? "(none)" : labelSummary,
                rationale: String(localized:
                    "Labels used for phone numbers (e.g., mobile, home, work).", comment: "Signal card rationale beneath the Phone number labels value."),
                displayHint: labelEntries.isEmpty ? .plain : .keyValue,
                entries: labelEntries.isEmpty ? nil : labelEntries))
        return signals
    }
}

private final class PhoneLabelCounter {
    private var counts: [String: Int] = [:]

    func increment(_ rawLabel: String) {
        let normalized = CNLabeledValue<NSString>.localizedString(forLabel: rawLabel)
        counts[normalized, default: 0] += 1
    }

    func summary() -> String {
        counts
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { "\($0.key):\($0.value)" }
            .joined(separator: ", ")
    }

    func entries() -> [SignalEntry] {
        counts
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { SignalEntry(label: $0.key, value: String($0.value)) }
    }
}
