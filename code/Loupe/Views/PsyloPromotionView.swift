//
//  PsyloPromotionView.swift
//  Loupe
//
//  Reusable promotion card for Psylo, Mysk's privacy-first browser.
//

import SwiftUI

struct PsyloPromotionView: View {
    private let appStoreURL = URL(string: "https://apps.apple.com/app/psylo-private-browser-proxy/id6741358035")!
    private let articleURL = URL(string: "https://mysk.blog/2025/06/17/introducing-psylo/")!

    private let promoTint = Color.purple

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 72

    var body: some View {
        VStack(spacing: 16) {
            iconHero
            copy
            actions
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .tint(promoTint)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Sections

    private var iconHero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            promoTint.opacity(0.38),
                            promoTint.opacity(0.0),
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: iconSize * 0.7
                    )
                )
                .frame(width: iconSize * 1.4, height: iconSize * 1.4)
                .blur(radius: 8)

            Image("psylo-icon")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .frame(height: iconSize)
        .accessibilityHidden(true)
    }

    private var copy: some View {
        VStack(spacing: 8) {
            Text("Enjoying Loupe? Check out Psylo")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Loupe is a free, open source research app from Mysk. If this work helps you understand what apps can learn about your device, try Psylo: our privacy-first browser for iOS and iPadOS with proxy-backed browsing, isolated tabs, and anti-fingerprinting protections.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Link(destination: appStoreURL) {
                Text("Download Psylo")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .compatibleProminentButtonStyle()
            .controlSize(.large)

            Link(destination: articleURL) {
                HStack(spacing: 4) {
                    Text("Why we built Psylo")
                    Image(systemName: "arrow.up.right")
                        .imageScale(.small)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(promoTint)
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            promoTint.opacity(0.18),
                            promoTint.opacity(0.02),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(promoTint.opacity(0.25), lineWidth: 1)
        }
    }
}

#Preview {
    PsyloPromotionView()
        .padding()
}
