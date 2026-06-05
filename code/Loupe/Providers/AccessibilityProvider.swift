//
//  AccessibilityProvider.swift
//  Loupe
//
//  Every accessibility flag is silently readable. Each one is a boolean
//  with a low prior of being enabled, so each "on" contributes several
//  bits. Stacked together this is one of the strongest passive surfaces.
//

import Foundation

struct AccessibilityProvider: SignalProvider {
    let category: SignalCategory = .accessibility

    private struct StandaloneFlag {
        let key: String
        let displayName: String
        let value: () -> Bool
        let rationale: String
    }

    private let standalone: [StandaloneFlag] = [
        StandaloneFlag(
            key: "voiceOverRunning",
            displayName: String(localized: "VoiceOver running", comment: "Signal card name in the Accessibility category — whether the VoiceOver screen reader is active."),
            value: { PlatformAccessibility.isVoiceOverRunning },
            rationale: String(localized: "Whether the VoiceOver screen reader is active.", comment: "Signal card rationale beneath the VoiceOver running value.")),
        StandaloneFlag(
            key: "switchControlRunning",
            displayName: String(localized: "Switch Control running", comment: "Signal card name in the Accessibility category — whether Switch Control is active."),
            value: { PlatformAccessibility.isSwitchControlRunning },
            rationale: String(localized: "Whether Switch Control is active.", comment: "Signal card rationale beneath the Switch Control running value.")),
        StandaloneFlag(
            key: "guidedAccessEnabled",
            displayName: String(localized: "Guided Access active", comment: "Signal card name in the Accessibility category — whether Guided Access is active."),
            value: { PlatformAccessibility.isGuidedAccessEnabled },
            rationale: String(localized: "Whether Guided Access is active.", comment: "Signal card rationale beneath the Guided Access active value.")),
        StandaloneFlag(
            key: "grayscaleEnabled",
            displayName: String(localized: "Grayscale color filter", comment: "Signal card name in the Accessibility category — whether the grayscale color filter is on."),
            value: { PlatformAccessibility.isGrayscaleEnabled },
            rationale: String(localized: "Whether the grayscale color filter is on.", comment: "Signal card rationale beneath the Grayscale color filter value.")),
        StandaloneFlag(
            key: "invertColorsEnabled",
            displayName: String(localized: "Invert Colors", comment: "Signal card name in the Accessibility category — whether Classic Invert Colors is on."),
            value: { PlatformAccessibility.isInvertColorsEnabled },
            rationale: String(localized: "Whether Classic Invert Colors is on.", comment: "Signal card rationale beneath the Invert Colors value.")),
        StandaloneFlag(
            key: "reduceMotionEnabled",
            displayName: String(localized: "Reduce Motion", comment: "Signal card name in the Accessibility category — whether Reduce Motion is on."),
            value: { PlatformAccessibility.isReduceMotionEnabled },
            rationale: String(localized: "Whether Reduce Motion is on.", comment: "Signal card rationale beneath the Reduce Motion value.")),
    ]

    private struct MergedFlag {
        let label: String
        let value: () -> Bool
    }

    private let merged: [MergedFlag] = [
        MergedFlag(label: String(localized: "AssistiveTouch", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isAssistiveTouchRunning }),
        MergedFlag(label: String(localized: "ShakeToUndo", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isShakeToUndoEnabled }),
        MergedFlag(label: String(localized: "BoldText", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isBoldTextEnabled }),
        MergedFlag(label: String(localized: "IncreaseContrast", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isDarkerSystemColorsEnabled }),
        MergedFlag(label: String(localized: "ReduceTransparency", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isReduceTransparencyEnabled }),
        MergedFlag(label: String(localized: "MonoAudio", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isMonoAudioEnabled }),
        MergedFlag(label: String(localized: "SpeakScreen", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isSpeakScreenEnabled }),
        MergedFlag(label: String(localized: "SpeakSelection", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isSpeakSelectionEnabled }),
        MergedFlag(label: String(localized: "ClosedCaptioning", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isClosedCaptioningEnabled }),
        MergedFlag(label: String(localized: "VideoAutoplay", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isVideoAutoplayEnabled }),
        MergedFlag(label: String(localized: "DifferentiateWithoutColor", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.shouldDifferentiateWithoutColor }),
        MergedFlag(label: String(localized: "ButtonShapes", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.buttonShapesEnabled }),
        MergedFlag(label: String(localized: "OnOffLabels", comment: "Compact accessibility-flag label joined into the 'Other active flags' value in the Accessibility category. Matches Apple's UIKit API name."), value: { PlatformAccessibility.isOnOffSwitchLabelsEnabled }),
    ]

    func collect() async -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []

        for flag in standalone {
            signals.append(
                .make(
                    flag.key,
                    category: category,
                    name: flag.displayName,
                    value: String(flag.value()),
                    rationale: flag.rationale))
        }

        let activeLabels = merged.compactMap { $0.value() ? $0.label : nil }
        let value = activeLabels.isEmpty ? String(localized: "none enabled", comment: "Placeholder value shown in the 'Other active flags' card when no accessibility flags are currently turned on.") : activeLabels.joined(separator: ", ")
        signals.append(
            .make(
                "activeFlags",
                category: category,
                name: String(localized: "Other active flags", comment: "Signal card name in the Accessibility category — a comma-separated list of additional accessibility flags currently turned on."),
                value: value,
                rationale:
                    String(localized: "Additional accessibility flags any app can check. Each one you've turned on adds a distinguishing detail.", comment: "Signal card rationale beneath the Other active flags value.")))

        if let info = PlatformScreen.displayInfo() {
            signals.append(
                .make(
                    "userInterfaceStyle",
                    category: category,
                    name: String(localized: "userInterfaceStyle", comment: "Signal card name in the Accessibility category — Apple's UITraitCollection property name for light/dark mode."),
                    value: info.userInterfaceStyle,
                    rationale: String(localized: "Light or dark mode preference.", comment: "Signal card rationale beneath the userInterfaceStyle value.")))
            signals.append(
                .make(
                    "accessibilityContrast",
                    category: category,
                    name: String(localized: "accessibilityContrast", comment: "Signal card name in the Accessibility category — Apple's UITraitCollection property name for Increase Contrast."),
                    value: info.accessibilityContrast,
                    rationale: String(localized: "Whether Increase Contrast is on.", comment: "Signal card rationale beneath the accessibilityContrast value.")))
        }
        return signals
    }
}
