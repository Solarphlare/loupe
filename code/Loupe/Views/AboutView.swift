//
//  AboutView.swift
//  Loupe
//
//  Modal "About" sheet shown from the home toolbar. Surfaces the app
//  version, links to mysk.co, and a way to replay the first-launch
//  onboarding flow without resetting the app.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showOnboarding") private var showOnboarding = false

    private let sourceCodeURL = URL(string: "https://github.com/mysk-research/loupe")!
    private let websiteURL = URL(string: "https://mysk.co")!
    private let blogURL = URL(string: "https://mysk.blog")!
    private let xURL = URL(string: "https://x.com/mysk_co")!
    private let mastodonURL = URL(string: "https://mastodon.social/@mysk")!
    private let rateAppURL = URL(string: "itms-apps://apps.apple.com/app/id6766152470?action=write-review")!

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    header
                }
                
                Section("Links") {
                    Link(destination: sourceCodeURL) {
                        Label("Source Code", systemImage: "text.page")
                    }
                }

                Section("About Mysk") {
                    Link(destination: websiteURL) {
                        Label("Website", systemImage: "globe")
                    }
                    Link(destination: blogURL) {
                        Label("Blog", systemImage: "newspaper")
                    }
                    Link(destination: xURL) {
                        Label("X", systemImage: "bird")
                    }
                    Link(destination: mastodonURL) {
                        Label("Mastodon", systemImage: "bubble.left.and.bubble.right")
                    }
                }

                Section {
                    Link(destination: rateAppURL) {
                        Label("Rate Loupe", systemImage: "star")
                    }
                    Button {
                        replayOnboarding()
                    } label: {
                        Label("See Onboarding Again", systemImage: "play.rectangle")
                    }
                }

                Section {
                    PsyloPromotionView()
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                Section {
                    EmptyView()
                } footer: {
                    creditsFooter
                }
            }
            .navigationTitle("About")
            .platformInlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            Image("loupe-icon")
                .resizable()
                .scaledToFit()
                .background(Color.accent)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Loupe")
                    .font(.title.bold())
                Text("Version \(appVersion) (Build \(appBuild))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var creditsFooter: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("Made by Mysk")
                .font(.footnote.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Actions

    private func replayOnboarding() {
        showOnboarding = true
        dismiss()
    }

    // MARK: - Version info

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

#Preview {
    AboutView()
}
