//
//  OnboardingPageView.swift
//  Loupe
//
//  Renders a single onboarding page. Standard pages show hero artwork,
//  highlight pages show a few live narrative cards, and the .tiers
//  variant stays driven by Sensitivity.allCases so the onboarding
//  remains in sync with the real classification.
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                switch page.kind {
                case .standard:
                    standardLayout
                case .highlights:
                    highlightsLayout
                case .apps:
                    appsLayout
                case .tiers:
                    tiersLayout
                }

                Spacer(minLength: 24)
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .compatibleScrollEdgeStyleSoft()
    }

    // MARK: - Layouts

    @ViewBuilder
    private var standardLayout: some View {
        if let artwork = page.artwork {
            HeroArtworkView(artwork: artwork)
                .padding(.bottom, 8)
        }

        Text(page.title)
            .font(.largeTitle.weight(.bold))
            .multilineTextAlignment(.center)
            .shadow(radius: 10)

        Text(page.body)
            .font(.title3)
            .shadow(radius: 10)
            .multilineTextAlignment(.center)
    }

    private var highlightsLayout: some View {
        VStack(spacing: 20) {
            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(.title3)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(Self.highlightItems) { item in
                    NarrativeHighlightCard(item: item)
                }
                if Self.bootDateAvailable {
                    TimelineView(.animation) { context in
                        if let item = FingerprintNarrative.uptimeItem(at: context.date) {
                            NarrativeHighlightCard(item: item)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private var tiersLayout: some View {
        VStack(spacing: 20) {
            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(.title3)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(Sensitivity.allCases) { tier in
                    TierCardView(tier: tier)
                }
            }
            .padding(.top, 8)
        }
    }

    private var appsLayout: some View {
        VStack(spacing: 20) {
            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(.title3)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(OnboardingContent.appInferenceItems) { item in
                    NarrativeHighlightCard(item: item)
                }
            }
            .padding(.top, 8)
        }
    }

    private static var highlightItems: [NarrativeItem] {
        let liveItems = Array(FingerprintNarrative.items())
        return liveItems
    }

    private static var bootDateAvailable: Bool {
        FingerprintNarrative.bootDate() != nil
    }
}

private struct HeroArtworkView: View {
    let artwork: OnboardingPage.Artwork

    var body: some View {
        switch artwork {
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 6)
                .accessibilityHidden(true)
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 90, weight: .thin))
                .foregroundStyle(.accent)
                .accessibilityHidden(true)
        }
    }
}

private struct NarrativeHighlightCard: View {
    let item: NarrativeItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.headline)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.basis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct TierCardView: View {
    let tier: Sensitivity

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: tier.symbolName)
                .font(.title3)
                .foregroundStyle(tier.tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(tier.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(tier.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

@MainActor
private func previewPage(id: String) -> OnboardingPage {
    OnboardingContent.pages.first(where: { $0.id == id })
        ?? OnboardingContent.pages[0]
}

#Preview("Standard") {
    ZStack {
        OnboardingGradientBackground()
        OnboardingPageView(page: previewPage(id: "welcome"))
    }
}

#Preview("Tiers") {
    ZStack {
        OnboardingGradientBackground()
        OnboardingPageView(page: previewPage(id: "tiers"))
    }
}

#Preview("Highlights") {
    ZStack {
        OnboardingGradientBackground()
        OnboardingPageView(page: previewPage(id: "highlights"))
    }
}

#Preview("Apps") {
    ZStack {
        OnboardingGradientBackground()
        OnboardingPageView(page: previewPage(id: "apps"))
    }
}
