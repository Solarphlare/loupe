//
//  MotionProvider.swift
//  Loupe
//
//  Reads the Core Motion APIs that genuinely trigger the iOS Motion prompt:
//  CMMotionActivityManager, CMPedometer, and CMAltimeter (relative + absolute).
//  Everything CMMotionManager exposes — including the fused CMDeviceMotion
//  frame — is permission-free and lives in DeviceMotionProvider.
//

import Foundation

#if os(iOS)
@preconcurrency import CoreMotion

final class MotionProvider: SignalProvider, LiveSignalProvider {
    let category: SignalCategory = .motion
    let center: PermissionCenter
    let updateInterval: TimeInterval = 0.2

    init(center: PermissionCenter) {
        self.center = center
    }

    func collect() async -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []

        if CMMotionActivityManager.isActivityAvailable() {
            let manager = CMMotionActivityManager()
            let end = Date()
            let start = end.addingTimeInterval(-60)
            let activity: CMMotionActivity? = await withCheckedContinuation { (continuation: CheckedContinuation<UncheckedSendableBox<CMMotionActivity?>, Never>) in
                manager.queryActivityStarting(from: start, to: end, to: .main) { activities, _ in
                    continuation.resume(returning: UncheckedSendableBox(activities?.last))
                }
            }.value
            if let activity {
                signals.append(Self.activitySignal(from: activity, category: category))
            }
        }

        if CMAltimeter.isRelativeAltitudeAvailable() {
            let altimeter = CMAltimeter()
            let state = AltimeterSampleState()
            let data: CMAltitudeData? = await withCheckedContinuation { (continuation: CheckedContinuation<UncheckedSendableBox<CMAltitudeData?>, Never>) in
                altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { data, _ in
                    state.finish(data, altimeter: altimeter, continuation: continuation)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    state.finish(nil, altimeter: altimeter, continuation: continuation)
                }
            }.value
            if let data {
                signals.append(contentsOf: Self.relativeAltitudeSignals(from: data, category: category))
            }
        }

        if CMAltimeter.isAbsoluteAltitudeAvailable() {
            let altimeter = CMAltimeter()
            let state = AbsoluteAltimeterSampleState()
            let data: CMAbsoluteAltitudeData? = await withCheckedContinuation { (continuation: CheckedContinuation<UncheckedSendableBox<CMAbsoluteAltitudeData?>, Never>) in
                altimeter.startAbsoluteAltitudeUpdates(to: OperationQueue.main) { data, _ in
                    state.finish(data, altimeter: altimeter, continuation: continuation)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    state.finish(nil, altimeter: altimeter, continuation: continuation)
                }
            }.value
            if let data {
                signals.append(contentsOf: Self.absoluteAltitudeSignals(from: data, category: category))
            }
        }

        if CMPedometer.isStepCountingAvailable() {
            let pedometer = CMPedometer()
            let start = Calendar.current.startOfDay(for: Date())
            let now = Date()
            let data: CMPedometerData? = await withCheckedContinuation { (continuation: CheckedContinuation<UncheckedSendableBox<CMPedometerData?>, Never>) in
                pedometer.queryPedometerData(from: start, to: now) { data, _ in
                    continuation.resume(returning: UncheckedSendableBox(data))
                }
            }.value
            if let data {
                signals.append(contentsOf: Self.pedometerSignals(from: data, category: category))
            }
        }

        return signals
    }

    func stream() -> AsyncStream<[FingerprintSignal]> {
        AsyncStream { continuation in
            let activityManager: CMMotionActivityManager? = CMMotionActivityManager.isActivityAvailable() ? CMMotionActivityManager() : nil
            let relativeAltimeter: CMAltimeter? = CMAltimeter.isRelativeAltitudeAvailable() ? CMAltimeter() : nil
            let absoluteAltimeter: CMAltimeter? = CMAltimeter.isAbsoluteAltitudeAvailable() ? CMAltimeter() : nil
            let pedometer: CMPedometer? = CMPedometer.isStepCountingAvailable() ? CMPedometer() : nil
            let category = self.category

            let queue = OperationQueue()
            queue.name = "Loupe.Motion.Live"
            queue.maxConcurrentOperationCount = 1

            let state = StreamState()

            let emit: () -> Void = {
                let snap = state.snapshot()
                var signals: [FingerprintSignal] = []
                if let activity = snap.activity {
                    signals.append(Self.activitySignal(from: activity, category: category))
                }
                if let altitude = snap.altitude {
                    signals.append(contentsOf: Self.relativeAltitudeSignals(from: altitude, category: category))
                }
                if let absolute = snap.absoluteAltitude {
                    signals.append(contentsOf: Self.absoluteAltitudeSignals(from: absolute, category: category))
                }
                if let ped = snap.pedometer {
                    signals.append(contentsOf: Self.pedometerSignals(from: ped, category: category))
                }
                continuation.yield(signals)
            }

            if let activityManager {
                activityManager.startActivityUpdates(to: queue) { activity in
                    guard let activity else { return }
                    state.setActivity(activity)
                    emit()
                }
            }

            if let relativeAltimeter {
                relativeAltimeter.startRelativeAltitudeUpdates(to: queue) { data, _ in
                    guard let data else { return }
                    state.setAltitude(data)
                    emit()
                }
            }

            if let absoluteAltimeter {
                absoluteAltimeter.startAbsoluteAltitudeUpdates(to: queue) { data, _ in
                    guard let data else { return }
                    state.setAbsoluteAltitude(data)
                    emit()
                }
            }

            if let pedometer {
                let start = Calendar.current.startOfDay(for: Date())
                pedometer.startUpdates(from: start) { data, _ in
                    guard let data else { return }
                    state.setPedometer(data)
                    emit()
                }
            }

            if activityManager == nil && relativeAltimeter == nil && absoluteAltimeter == nil && pedometer == nil {
                continuation.yield([])
                continuation.finish()
                return
            }

            emit()

            continuation.onTermination = { @Sendable _ in
                activityManager?.stopActivityUpdates()
                relativeAltimeter?.stopRelativeAltitudeUpdates()
                absoluteAltimeter?.stopAbsoluteAltitudeUpdates()
                pedometer?.stopUpdates()
            }
        }
    }

    // MARK: - Signal Builders

    private static func activitySignal(from activity: CMMotionActivity, category: SignalCategory) -> FingerprintSignal {
        var labels: [String] = []
        if activity.stationary { labels.append("stationary") }
        if activity.walking { labels.append("walking") }
        if activity.running { labels.append("running") }
        if activity.automotive { labels.append("automotive") }
        if activity.cycling { labels.append("cycling") }
        if activity.unknown || labels.isEmpty { labels.append("unknown") }
        let confidence: String
        switch activity.confidence {
        case .low: confidence = "low"
        case .medium: confidence = "medium"
        case .high: confidence = "high"
        @unknown default: confidence = "?"
        }
        let activityString = labels.joined(separator: "+")
        return .make(
            "activity",
            category: category,
            name: String(localized: "Current activity", comment: "Signal card name in the Motion & Sensors category — CMMotionActivity classification (e.g., walking, running)."),
            value: "\(activityString)  conf=\(confidence)",
            rationale: String(localized: "Activity classification (e.g., walking, running) and confidence level.", comment: "Signal card rationale beneath the Current activity value."),
            displayHint: .compound,
            entries: [
                SignalEntry(label: String(localized: "Activity", comment: "Current-activity sub-label. CMMotionActivity classification name(s)."), value: activityString),
                SignalEntry(label: String(localized: "Confidence", comment: "Current-activity sub-label. CMMotionActivity.confidence (low / medium / high)."), value: confidence),
            ])
    }

    private static func relativeAltitudeSignals(from data: CMAltitudeData, category: SignalCategory) -> [FingerprintSignal] {
        [
            .make(
                "altimeter.pressure",
                category: category,
                name: String(localized: "Air pressure (kPa)", comment: "Signal card name in the Motion & Sensors category — CMAltitudeData.pressure (barometric pressure in kPa)."),
                value: String(format: "%.4f", data.pressure.doubleValue),
                rationale: String(localized: "Barometric pressure reading.", comment: "Signal card rationale beneath the Air pressure value.")),
            .make(
                "altimeter.relativeAltitude",
                category: category,
                name: String(localized: "Relative altitude (m)", comment: "Signal card name in the Motion & Sensors category — CMAltitudeData.relativeAltitude (change in altitude since sensor start, in meters)."),
                value: String(format: "%+.2f", data.relativeAltitude.doubleValue),
                rationale: String(localized: "Change in altitude since the sensor started.", comment: "Signal card rationale beneath the Relative altitude value.")),
        ]
    }

    private static func absoluteAltitudeSignals(from data: CMAbsoluteAltitudeData, category: SignalCategory) -> [FingerprintSignal] {
        [
            .make(
                "altimeter.absoluteAltitude",
                category: category,
                name: String(localized: "Absolute altitude (m)", comment: "Signal card name in the Motion & Sensors category — CMAbsoluteAltitudeData.altitude (estimated altitude above sea level, in meters)."),
                value: String(format: "%.2f", data.altitude),
                rationale: String(localized: "Estimated absolute altitude above sea level.", comment: "Signal card rationale beneath the Absolute altitude value.")),
            .make(
                "altimeter.absoluteAccuracy",
                category: category,
                name: String(localized: "Absolute altitude accuracy (m)", comment: "Signal card name in the Motion & Sensors category — CMAbsoluteAltitudeData.accuracy (estimated accuracy of the altitude reading)."),
                value: String(format: "%.2f", data.accuracy),
                rationale: String(localized: "Estimated accuracy of the altitude reading.", comment: "Signal card rationale beneath the Absolute altitude accuracy value.")),
            .make(
                "altimeter.absolutePrecision",
                category: category,
                name: String(localized: "Absolute altitude precision (m)", comment: "Signal card name in the Motion & Sensors category — CMAbsoluteAltitudeData.precision (precision of the altitude reading)."),
                value: String(format: "%.2f", data.precision),
                rationale: String(localized: "Precision of the altitude reading.", comment: "Signal card rationale beneath the Absolute altitude precision value.")),
        ]
    }

    private static func pedometerSignals(from data: CMPedometerData, category: SignalCategory) -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []
        signals.append(
            .make(
                "pedometer.steps",
                category: category,
                name: String(localized: "Steps today", comment: "Signal card name in the Motion & Sensors category — CMPedometerData.numberOfSteps for today."),
                value: String(data.numberOfSteps.intValue),
                rationale: String(localized: "Estimated step count for today.", comment: "Signal card rationale beneath the Steps today value.")))
        if let distance = data.distance {
            signals.append(
                .make(
                    "pedometer.distance",
                    category: category,
                    name: String(localized: "Distance today (m)", comment: "Signal card name in the Motion & Sensors category — CMPedometerData.distance for today (in meters)."),
                    value: String(format: "%.1f", distance.doubleValue),
                    rationale: String(localized: "Estimated distance traveled today.", comment: "Signal card rationale beneath the Distance today value.")))
        }
        if let floors = data.floorsAscended {
            signals.append(
                .make(
                    "pedometer.floorsUp",
                    category: category,
                    name: String(localized: "Floors ascended", comment: "Signal card name in the Motion & Sensors category — CMPedometerData.floorsAscended for today."),
                    value: floors.stringValue,
                    rationale: String(localized: "Estimated floors ascended today.", comment: "Signal card rationale beneath the Floors ascended value.")))
        }
        if let floors = data.floorsDescended {
            signals.append(
                .make(
                    "pedometer.floorsDown",
                    category: category,
                    name: String(localized: "Floors descended", comment: "Signal card name in the Motion & Sensors category — CMPedometerData.floorsDescended for today."),
                    value: floors.stringValue,
                    rationale: String(localized: "Estimated floors descended today.", comment: "Signal card rationale beneath the Floors descended value.")))
        }
        if let pace = data.currentPace {
            signals.append(
                .make(
                    "pedometer.pace",
                    category: category,
                    name: String(localized: "Current pace (s/m)", comment: "Signal card name in the Motion & Sensors category — CMPedometerData.currentPace (seconds per meter)."),
                    value: String(format: "%.2f", pace.doubleValue),
                    rationale: String(localized: "Estimated pace of forward motion.", comment: "Signal card rationale beneath the Current pace value.")))
        }
        if let cadence = data.currentCadence {
            signals.append(
                .make(
                    "pedometer.cadence",
                    category: category,
                    name: String(localized: "Current cadence (steps/s)", comment: "Signal card name in the Motion & Sensors category — CMPedometerData.currentCadence (steps per second)."),
                    value: String(format: "%.2f", cadence.doubleValue),
                    rationale: String(localized: "Estimated cadence in steps per second.", comment: "Signal card rationale beneath the Current cadence value.")))
        }
        if let avgPace = data.averageActivePace {
            signals.append(
                .make(
                    "pedometer.averageActivePace",
                    category: category,
                    name: String(localized: "Average active pace (s/m)", comment: "Signal card name in the Motion & Sensors category — CMPedometerData.averageActivePace over the queried interval."),
                    value: String(format: "%.2f", avgPace.doubleValue),
                    rationale: String(localized: "Average active pace over the queried interval.", comment: "Signal card rationale beneath the Average active pace value.")))
        }
        return signals
    }
}

// MARK: - Sendable Box

/// Smuggles non-Sendable Core Motion values across continuation boundaries.
/// Safe here because each value is read once on a single concurrent path.
private struct UncheckedSendableBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}

// MARK: - Stream State

private final class StreamState: @unchecked Sendable {
    struct Snapshot {
        var activity: CMMotionActivity?
        var altitude: CMAltitudeData?
        var absoluteAltitude: CMAbsoluteAltitudeData?
        var pedometer: CMPedometerData?
    }

    private let lock = NSLock()
    private var current = Snapshot()

    func snapshot() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func setActivity(_ value: CMMotionActivity) {
        lock.lock(); current.activity = value; lock.unlock()
    }

    func setAltitude(_ value: CMAltitudeData) {
        lock.lock(); current.altitude = value; lock.unlock()
    }

    func setAbsoluteAltitude(_ value: CMAbsoluteAltitudeData) {
        lock.lock(); current.absoluteAltitude = value; lock.unlock()
    }

    func setPedometer(_ value: CMPedometerData) {
        lock.lock(); current.pedometer = value; lock.unlock()
    }
}

// MARK: - Altimeter Continuation Helpers

private final class AltimeterSampleState: @unchecked Sendable {
    private let lock = NSLock()
    private var resolved = false

    func finish(
        _ data: CMAltitudeData?,
        altimeter: CMAltimeter,
        continuation: CheckedContinuation<UncheckedSendableBox<CMAltitudeData?>, Never>
    ) {
        lock.lock()
        guard !resolved else {
            lock.unlock()
            return
        }
        resolved = true
        lock.unlock()

        altimeter.stopRelativeAltitudeUpdates()
        continuation.resume(returning: UncheckedSendableBox(data))
    }
}

private final class AbsoluteAltimeterSampleState: @unchecked Sendable {
    private let lock = NSLock()
    private var resolved = false

    func finish(
        _ data: CMAbsoluteAltitudeData?,
        altimeter: CMAltimeter,
        continuation: CheckedContinuation<UncheckedSendableBox<CMAbsoluteAltitudeData?>, Never>
    ) {
        lock.lock()
        guard !resolved else {
            lock.unlock()
            return
        }
        resolved = true
        lock.unlock()

        altimeter.stopAbsoluteAltitudeUpdates()
        continuation.resume(returning: UncheckedSendableBox(data))
    }
}

#else // macOS

struct MotionProvider: SignalProvider {
    let category: SignalCategory = .motion
    let center: PermissionCenter

    init(center: PermissionCenter) {
        self.center = center
    }

    func collect() async -> [FingerprintSignal] {
        [.make(
            "unavailable",
            category: category,
            name: String(localized: "Motion & Sensors", comment: "Signal card name in the Motion & Sensors category — placeholder shown on macOS where CoreMotion is unavailable."),
            value: String(localized: "Not available on macOS", comment: "Placeholder value shown when motion is unavailable on this platform."),
            rationale: String(localized: "CoreMotion is an iOS-only framework.", comment: "Signal card rationale beneath the Motion & Sensors placeholder on macOS."))]
    }
}
#endif
