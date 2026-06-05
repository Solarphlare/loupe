//
//  Sensitivity.swift
//  Loupe
//
//  Classification of how invasive a given fingerprinting signal is.
//

import SwiftUI

enum Sensitivity: String, Codable, Sendable, CaseIterable, Identifiable {
    case passive
    case permissioned
    case advanced

    var id: String { rawValue }

    @MainActor
    var title: String {
        switch self {
        case .passive: return String(localized: "Passive", comment: "Sensitivity tier title (full) for the passive tier.")
        case .permissioned: return String(localized: "Needs Permission", comment: "Sensitivity tier title (full) for the permissioned tier.")
        case .advanced: return String(localized: "Advanced", comment: "Sensitivity tier title (full) for the advanced tier.")
        }
    }

    @MainActor
    var shortTitle: String {
        switch self {
        case .passive: return String(localized: "Passive", comment: "Sensitivity tier short label, used as a chip in the home list.")
        case .permissioned: return String(localized: "Gated", comment: "Sensitivity tier short label, used as a chip in the home list.")
        case .advanced: return String(localized: "Advanced", comment: "Sensitivity tier short label, used as a chip in the home list.")
        }
    }

    @MainActor
    var blurb: String {
        switch self {
        case .passive:
            return String(localized: "Any app on your \(PlatformDevice.localizedModel) can read these. There's no prompt and nothing for you to see or approve.", comment: "Sensitivity tier description shown in onboarding and as the footer beneath the signal list on every passive-tier category screen. %@ is the device model name (e.g., iPhone, iPad).")
        case .permissioned:
            return String(localized: "\(PlatformDevice.systemName) shows a prompt the first time an app asks.", comment: "Sensitivity tier description shown in onboarding and as the footer beneath the signal list on every permissioned-tier category screen. %@ is the OS name (iOS, iPadOS, macOS).")
        case .advanced:
            return String(localized: "Clever uses of public APIs to extract more details than they were meant to.", comment: "Sensitivity tier description shown in onboarding and as the footer beneath the signal list on every advanced-tier category screen.")
        }
    }

    @MainActor
    var symbolName: String {
        switch self {
        case .passive: return "eye"
        case .permissioned: return "lock.shield"
        case .advanced: return "flask"
        }
    }

    @MainActor
    var tint: Color {
        switch self {
        case .passive: return .green
        case .permissioned: return .orange
        case .advanced: return .pink
        }
    }
}
