//
//  ScreenshotMode.swift
//  Loupe
//
//  A launch-argument gate used to swap live device readings for fixed
//  mock data when capturing App Store screenshots. Pass `-LoupeMockData`
//  to populate every screen with a consistent, believable persona, and
//  `-LoupeShowOnboarding` to start on the onboarding flow instead of the
//  home screen. Without these arguments the app behaves normally.
//

import Foundation

enum ScreenshotMode {
    /// True when the app is launched for screenshot capture with mock data.
    static let isActive = ProcessInfo.processInfo.arguments.contains("-LoupeMockData")

    /// Whether the onboarding flow should be shown in screenshot mode.
    /// Defaults to hidden so the home, category, and highlights screens are
    /// reachable without dismissing onboarding first.
    static let showsOnboarding = ProcessInfo.processInfo.arguments.contains("-LoupeShowOnboarding")
}
