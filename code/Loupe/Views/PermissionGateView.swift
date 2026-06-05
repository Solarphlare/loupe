//
//  PermissionGateView.swift
//  Loupe
//
//  Empty state shown inside a category detail when the underlying
//  permission hasn't been granted yet. One tap walks the user through
//  the system prompt via PermissionCenter.
//

import SwiftUI

struct PermissionGateView: View {
    let category: SignalCategory
    let loadState: CategoryStore.LoadState
    let onEnable: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize = 72
    @ScaledMetric(relativeTo: .largeTitle) private var symbolBackgroundSize = 140

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: category.symbolName)
                    .font(.system(size: symbolSize, weight: .light))
                    .foregroundStyle(category.sensitivity.tint)
                    .padding()
                    .background(
                        Circle()
                            .fill(category.sensitivity.tint.opacity(0.15))
                            .frame(width: symbolBackgroundSize, height: symbolBackgroundSize)
                    )
                    .accessibilityHidden(true)
                Text(category.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                if let permission = category.permission {
                    Text(permission.rationale)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                enableButton
                statusLabel
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var enableButton: some View {
        switch loadState {
        case .loading:
            ProgressView().controlSize(.large)
        case .denied(let reason):
            VStack(spacing: 10) {
                Button(action: onEnable) {
                    Label("Try again", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                settingsLink
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        default:
            Button(action: onEnable) {
                Label("Enable \(category.permission?.title ?? category.title)", systemImage: "lock.open.fill")
                    .font(.headline)
                    .padding(.horizontal)
            }
            .compatibleProminentButtonStyle()
            .controlSize(.large)
            .tint(category.sensitivity.tint)
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch loadState {
        case .denied:
            Text("You can also change this later in Settings > Privacy & Security.")
                .modifier(StatusLabelStyle())
        default:
            Text("Tapping Enable shows the \(PlatformDevice.systemName) permission prompt. You can revoke access later in Settings.")
                .modifier(StatusLabelStyle())
        }
    }

    private var settingsLink: some View {
        Link(destination: PlatformApplication.openSettingsURL) {
            Label("Open Settings", systemImage: "gear")
        }
        .font(.caption.weight(.semibold))
    }
}

private struct StatusLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }
}
