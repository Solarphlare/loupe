//
//  OnboardingPage.swift
//  Loupe
//
//  Static model for the first-launch onboarding flow. Pages use either
//  a hero image or SF Symbol, then keep their copy short and plain so
//  non-technical users understand what Loupe is showing them.
//

import SwiftUI

struct OnboardingPage: Identifiable, Hashable {
    enum Kind: Hashable {
        case standard
        case highlights
        case apps
        case tiers
    }

    enum Artwork: Hashable {
        case asset(String)
        case symbol(String)
    }

    let id: String
    let kind: Kind
    let artwork: Artwork?
    let title: String
    let body: String
}

@MainActor
enum OnboardingContent {
    static var pages: [OnboardingPage] {
        allPages.filter { page in
            page.kind != .apps || !appInferenceItems.isEmpty
        }
    }

    static var appInferenceItems: [NarrativeItem] {
        AppInferenceEngine.detectedInferences()
    }

    private static var allPages: [OnboardingPage] {
        [
            OnboardingPage(
                id: "welcome",
                kind: .standard,
                artwork: .asset("loupe-icon"),
                title: String(localized: "Welcome to Loupe", comment: "Onboarding page title — page 1 (welcome)."),
                body: String(
                    localized:
                        """
                        Ever wondered how advertisers track you online across different apps?

                        Any app you have can quietly read many small details about your \(PlatformDevice.marketingName): your region, time zone, keyboard languages, system settings, and much more.
                        """,
                    comment: "Onboarding page body — page 1 (welcome), introduces the topic of cross-app tracking. %@ is the marketing name (e.g., 'iPhone 16 Pro')."
                )
            ),
            OnboardingPage(
                id: "fingerprinting",
                kind: .standard,
                artwork: .symbol("person.crop.square.filled.and.at.rectangle"),
                title: String(localized: "What is fingerprinting?", comment: "Onboarding page title — page 2, topic: explanation of fingerprinting."),
                body: String(
                    localized:
                        """
                        Trackers don't need your name, email, or location to recognize you online. The everyday details of your \(PlatformDevice.localizedModel), like its settings, languages, and customizations, are often enough.

                        When the same combination of these details shows up again across apps and websites, it stands out. That recurring pattern is your fingerprint.
                        """,
                    comment: "Onboarding page body — page 2, topic: explanation of fingerprinting. %@ is the device model name (e.g., iPhone, iPad)."
                )
            ),
            OnboardingPage(
                id: "highlights",
                kind: .highlights,
                artwork: nil,
                title: String(localized: "What your apps can see", comment: "Onboarding page title — page 3, topic: highlights of passively-readable signals."),
                body: String(
                    localized:
                        "Here are some of the things your apps can see. Each one isn't necessarily unique on its own, but together they can be enough to form a fingerprint that follows you online.",
                    comment: "Onboarding page body — page 3, topic: highlights of passively-readable signals. Intros the narrative cards that follow."
                )
            ),
            OnboardingPage(
                id: "apps",
                kind: .apps,
                artwork: nil,
                title: String(localized: "What your installed apps say about you", comment: "Onboarding page title — page 4, topic: inferences from installed apps."),
                body: String(
                    localized:
                        "Apps can quietly check which other apps you have installed. That mix hints at your work, travel, finances, hobbies, and habits.",
                    comment: "Onboarding page body — page 4, topic: inferences from installed apps."
                )
            ),
            OnboardingPage(
                id: "tiers",
                kind: .tiers,
                artwork: nil,
                title: String(localized: "Loupe shows you all of that in one place", comment: "Onboarding page title — page 5, topic: the three sensitivity tiers Loupe organizes signals into."),
                body: String(
                    localized:
                        "Some readings are passively visible to apps with no prompt at all, while others require your permission.",
                    comment: "Onboarding page body — page 5, topic: the three sensitivity tiers Loupe organizes signals into."
                )
            ),
            OnboardingPage(
                id: "stays-local",
                kind: .standard,
                artwork: .symbol("lock.iphone"),
                title: String(localized: "Nothing leaves your \(PlatformDevice.localizedModel)", comment: "Onboarding page title — page 6, topic: privacy reassurance. %@ is the device model name (e.g., iPhone, iPad)."),
                body: String(
                    localized:
                        """
                        Loupe reads these signals on your \(PlatformDevice.localizedModel) and keeps them here. Nothing is uploaded, synced, or shared unless you choose to export.
                        
                        Loupe is also free and open source, so you can see exactly how it works.
                        """,
                    comment: "Onboarding page body — page 6, topic: privacy reassurance. %@ is the device model name (e.g., iPhone, iPad)."
                )
            ),
        ]
    }
}
