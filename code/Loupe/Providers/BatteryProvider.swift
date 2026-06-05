//
//  BatteryProvider.swift
//  Loupe
//
//  Battery level and state are a classic time-domain fingerprint: charge
//  level changes slowly, so a web site revisited in the same minute gets
//  the same reading and can re-identify the user.
//

import Foundation

final class BatteryProvider: SignalProvider, LiveSignalProvider {
    let category: SignalCategory = .battery
    let updateInterval: TimeInterval = 5.0

    func collect() async -> [FingerprintSignal] {
        buildSignals()
    }

    func stream() -> AsyncStream<[FingerprintSignal]> {
        AsyncStream { continuation in
            PlatformDevice.isBatteryMonitoringEnabled = true
            continuation.yield(self.buildSignals())

            let task = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: UInt64(5.0 * 1_000_000_000))
                    if Task.isCancelled { break }
                    guard let self else { break }
                    continuation.yield(self.buildSignals())
                }
                continuation.finish()
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    private func buildSignals() -> [FingerprintSignal] {
        let wasEnabled = PlatformDevice.isBatteryMonitoringEnabled
        PlatformDevice.isBatteryMonitoringEnabled = true
        defer { if !wasEnabled { PlatformDevice.isBatteryMonitoringEnabled = wasEnabled } }

        var signals: [FingerprintSignal] = []
        let level = PlatformDevice.batteryLevel
        let levelString = level < 0 ? "unknown" : String(format: "%.2f", level)
        let stateString = "\(PlatformDevice.batteryState)"
        let value = "\(levelString) / \(stateString)"
        signals.append(
            .make(
                "batteryLevel",
                category: category,
                name: String(localized: "Battery level & state", comment: "Signal card name in the Battery & Power category — current battery charge level and charging state."),
                value: value,
                rationale:
                    String(localized: "Battery charge level and charging state. Changes slowly, so the value can persist across short sessions.", comment: "Signal card rationale beneath the Battery level & state value."),
                displayHint: .compound,
                entries: [
                    SignalEntry(label: String(localized: "Level", comment: "Battery sub-label — the current charge level (0.00–1.00)."), value: levelString),
                    SignalEntry(label: String(localized: "State", comment: "Battery sub-label — the charging state (charging, full, unplugged, unknown)."), value: stateString),
                ]))
        signals.append(
            .make(
                "lowPowerMode",
                category: category,
                name: String(localized: "Low power mode", comment: "Signal card name in the Battery & Power category — whether Low Power Mode is currently turned on."),
                value: String(ProcessInfo.processInfo.isLowPowerModeEnabled),
                rationale: String(localized: "Whether you have Low Power Mode turned on.", comment: "Signal card rationale beneath the Low power mode value.")))
        signals.append(
            .make(
                "thermalState",
                category: category,
                name: String(localized: "Thermal state", comment: "Signal card name in the Battery & Power category — Apple's ProcessInfo.thermalState reading."),
                value: describe(ProcessInfo.processInfo.thermalState),
                rationale: String(localized: "Current thermal state. Can reflect workload or charging.", comment: "Signal card rationale beneath the Thermal state value.")))
        return signals
    }

    private func describe(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}
