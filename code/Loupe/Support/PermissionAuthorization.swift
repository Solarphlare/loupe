//
//  PermissionAuthorization.swift
//  Loupe
//
//  Unified representation of the authorization state returned by the
//  permission-gated APIs. Apple's frameworks each use slightly
//  different enums; this collapses them to one vocabulary.
//

import Foundation

nonisolated enum PermissionAuthorization: Sendable, Equatable {
    case notDetermined
    case authorized
    case requested
    case limited
    case denied
    case restricted
    case unavailable(String)

    var isUsable: Bool {
        switch self {
        case .authorized, .requested, .limited: return true
        default: return false
        }
    }

    var displayName: String {
        switch self {
        case .notDetermined: return String(localized: "Not determined", comment: "Authorization status label — the system has not yet asked the user.")
        case .authorized: return String(localized: "Allowed", comment: "Authorization status label — the user has fully granted the permission.")
        case .requested: return String(localized: "Requested", comment: "Authorization status label — Loupe has asked the system to prompt the user.")
        case .limited: return String(localized: "Limited", comment: "Authorization status label — partial access (e.g. Photos: selected items only).")
        case .denied: return String(localized: "Denied", comment: "Authorization status label — the user explicitly declined.")
        case .restricted: return String(localized: "Restricted", comment: "Authorization status label — blocked by a system policy such as Screen Time / parental controls.")
        case .unavailable(let reason): return reason
        }
    }
}
