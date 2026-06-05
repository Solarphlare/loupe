//
//  CategoryRowView.swift
//  Loupe
//
//  Single row on the home list. Shows symbol, title/subtitle, a
//  sensitivity badge, and either a "Tap to collect" or a signal count
//  depending on load state.
//

import SwiftUI

struct CategoryRowView: View {
    let category: SignalCategory
    let state: CategoryStore.LoadState
    let count: Int

    @ScaledMetric(relativeTo: .body) private var iconFrame = 42
    @ScaledMetric(relativeTo: .body) private var symbolSize = 18

    var body: some View {
        HStack(spacing: 14) {
            icon
            VStack(alignment: .leading) {
                Text(category.title)
                    .font(.headline)
                Text(category.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            trailing
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.title), \(category.subtitle)")
        .accessibilityValue(accessibilityValue)
        .accessibilityIdentifier("category.\(category.rawValue)")
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(category.sensitivity.tint.opacity(0.15))
                .frame(width: iconFrame, height: iconFrame)
            Image(systemName: category.symbolName)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(category.sensitivity.tint)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var trailing: some View {
        switch state {
        case .idle:
            Image(systemName: category.sensitivity == .passive ? "hourglass" : "lock.fill")
                .foregroundStyle(.tertiary)
        case .loading:
            ProgressView().controlSize(.small)
        case .loaded:
            EmptyView()
        case .denied:
            Image(systemName: "xmark.shield.fill")
                .foregroundStyle(.red)
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .idle:
            return category.sensitivity == .permissioned ? String(localized: "Needs permission", comment: "Accessibility value on a home-list row indicating the category is gated by a system permission prompt.") : String(localized: "Not collected", comment: "Accessibility value on a home-list row indicating the category has not yet been collected.")
        case .loading:
            return String(localized: "Loading", comment: "Accessibility value on a home-list row indicating signals for this category are currently being collected.")
        case .loaded:
            return String(localized: "\(count) signals collected", comment: "Accessibility value on a home-list row indicating how many signals were collected. %lld is the signal count.")
        case .denied(let reason):
            return String(localized: "Denied, \(reason)", comment: "Accessibility value on a home-list row indicating the permission was denied. %@ is the reason / authorization status (e.g., 'Denied', 'Restricted').")
        }
    }
}
