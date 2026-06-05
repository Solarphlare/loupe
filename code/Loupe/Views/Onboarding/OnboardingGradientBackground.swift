//
//  OnboardingGradientBackground.swift
//  Loupe
//
//  Subtle system-background wash that sits behind the onboarding pages.
//  On iOS 18 / macOS 15 and newer the background is a 3x3 MeshGradient
//  with a faint animated accent tint; on iOS 17 / macOS 14 it falls back
//  to a static LinearGradient.
//

import SwiftUI

struct OnboardingGradientBackground: View {
    var body: some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            AnimatedMeshBackground()
        } else {
            SubtleGradientFallback()
                .ignoresSafeArea()
        }
    }
}

// MARK: - Palette

private enum OnboardingGradientPalette {
    #if os(iOS)
    static let systemBackground = Color(uiColor: .systemBackground)
    #elseif os(macOS)
    static let systemBackground = Color(nsColor: .windowBackgroundColor)
    #endif

    static let accent = Color.accentColor

    static let fallback: [Color] = [
        accent.opacity(0.33),
        .clear,
        .clear,
        accent.opacity(0.33),
    ]
}

// MARK: - Static fallback

private struct SubtleGradientFallback: View {
    var body: some View {
        OnboardingGradientPalette.systemBackground
            .overlay(
                LinearGradient(
                    colors: OnboardingGradientPalette.fallback,
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
    }
}

// MARK: - Animated mesh (iOS 18+ / macOS 15+)

@available(iOS 18.0, macOS 15.0, *)
private struct AnimatedMeshBackground: View {
    private let points: [SIMD2<Float>] = [
        SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
        SIMD2<Float>(0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1, 0.5),
        SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1),
    ]

    var body: some View {
        OnboardingGradientPalette.systemBackground
            .overlay {
                TimelineView(.animation) { timeline in
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: points,
                        colors: animatedColors(for: timeline.date),
                        background: .clear,
                        smoothsColors: true
                    )
                }
            }
            .ignoresSafeArea()
    }

    private func animatedColors(for date: Date) -> [Color] {
        let phase = date.timeIntervalSinceReferenceDate * 0.45
        let pulse = (sin(phase) + 1) / 2
        let topOpacity = 0.18 + pulse * 0.06
        let topEdgeOpacity = 0.10 + pulse * 0.04
        let bottomOpacity = 0.14 + pulse * 0.05
        let bottomEdgeOpacity = 0.08 + pulse * 0.03

        return [
            OnboardingGradientPalette.accent.opacity(topEdgeOpacity),
            OnboardingGradientPalette.accent.opacity(topOpacity),
            OnboardingGradientPalette.accent.opacity(topEdgeOpacity),
            .clear, .clear, .clear,
            OnboardingGradientPalette.accent.opacity(bottomEdgeOpacity),
            OnboardingGradientPalette.accent.opacity(bottomOpacity),
            OnboardingGradientPalette.accent.opacity(bottomEdgeOpacity),
        ]
    }
}

#Preview {
    OnboardingGradientBackground()
}
