//
//  LocationProvider.swift
//  Loupe
//
//  Asks CLLocationManager for one location update. Also reports heading,
//  reduced-accuracy flag, and monitoring capabilities.
//

import CoreLocation
import Foundation

@MainActor
final class LocationProvider: SignalProvider, LiveSignalProvider {
    let category: SignalCategory = .location
    let center: PermissionCenter
    let updateInterval: TimeInterval = 1.0

    init(center: PermissionCenter) {
        self.center = center
    }

    func collect() async -> [FingerprintSignal] {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        let sampler = LocationSampler.shared
        let location = await sampler.sampleLocation()
        return buildSignals(manager: manager, location: location)
    }

    func stream() -> AsyncStream<[FingerprintSignal]> {
        AsyncStream { continuation in
            let streamer = LocationStreamer { [weak self] location in
                guard let self else { return }
                let manager = CLLocationManager()
                let signals = self.buildSignals(manager: manager, location: location)
                continuation.yield(signals)
            }
            streamer.start()

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    streamer.stop()
                }
            }
        }
    }

    private func buildSignals(manager: CLLocationManager, location: CLLocation?) -> [FingerprintSignal] {
        var signals: [FingerprintSignal] = []
        signals.append(
            .make(
                "authorization", category: category,
                name: String(localized: "Authorization", comment: "Signal card name in the Location category — CLLocationManager.authorizationStatus."),
                value: describe(manager.authorizationStatus),
                rationale: String(localized: "Location authorization status.", comment: "Signal card rationale beneath the Authorization value.")))
        signals.append(
            .make(
                "accuracyAuthorization", category: category,
                name: String(localized: "Accuracy authorization", comment: "Signal card name in the Location category — CLLocationManager.accuracyAuthorization (Precise vs Reduced)."),
                value: describe(manager.accuracyAuthorization),
                rationale: String(localized: "Precise or Reduced accuracy. Determines the granularity of reported coordinates.", comment: "Signal card rationale beneath the Accuracy authorization value.")))

        if let location {
            signals.append(
                .make(
                    "coordinate", category: category,
                    name: String(localized: "Coordinate", comment: "Signal card name in the Location category — latitude/longitude pair."),
                    value: String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude),
                    rationale: String(localized: "Your latitude and longitude. With Reduced accuracy, this is a general area rather than a precise point.", comment: "Signal card rationale beneath the Coordinate value.")))
            signals.append(
                .make(
                    "altitude", category: category,
                    name: String(localized: "Altitude (m)", comment: "Signal card name in the Location category — altitude in meters above sea level."),
                    value: String(format: "%.1f", location.altitude),
                    rationale: String(localized: "Altitude above sea level.", comment: "Signal card rationale beneath the Altitude value.")))
            signals.append(
                .make(
                    "horizontalAccuracy", category: category,
                    name: String(localized: "Horizontal accuracy", comment: "Signal card name in the Location category — CLLocation.horizontalAccuracy (radius of uncertainty)."),
                    value: String(format: "%.1f m", location.horizontalAccuracy),
                    rationale: String(localized: "Precision of the coordinate. Larger values mean less certainty.", comment: "Signal card rationale beneath the Horizontal accuracy value.")))
            signals.append(
                .make(
                    "verticalAccuracy", category: category,
                    name: String(localized: "Vertical accuracy", comment: "Signal card name in the Location category — CLLocation.verticalAccuracy (altitude uncertainty)."),
                    value: String(format: "%.1f m", location.verticalAccuracy),
                    rationale: String(localized: "Precision of the altitude reading. Negative means unavailable.", comment: "Signal card rationale beneath the Vertical accuracy value.")))
            signals.append(
                .make(
                    "floor", category: category,
                    name: String(localized: "Floor", comment: "Signal card name in the Location category — CLLocation.floor (indoor floor level)."),
                    value: location.floor.map { String($0.level) } ?? "n/a",
                    rationale: String(localized: "Indoor floor level, when available in mapped buildings.", comment: "Signal card rationale beneath the Floor value.")))
            signals.append(
                .make(
                    "speed", category: category,
                    name: String(localized: "Speed", comment: "Signal card name in the Location category — CLLocation.speed (meters per second)."),
                    value: String(format: "%.2f m/s", location.speed),
                    rationale: String(localized: "Current speed. A value of -1 means unknown.", comment: "Signal card rationale beneath the Speed value.")))
            signals.append(
                .make(
                    "course", category: category,
                    name: String(localized: "Course", comment: "Signal card name in the Location category — CLLocation.course (direction of travel in degrees)."),
                    value: String(format: "%.1f°", location.course),
                    rationale: String(localized: "Direction of travel. A value of -1 means unknown.", comment: "Signal card rationale beneath the Course value.")))
        }
        return signals
    }

    private func describe(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }

    private func describe(_ accuracy: CLAccuracyAuthorization) -> String {
        switch accuracy {
        case .fullAccuracy: return "full"
        case .reducedAccuracy: return "reduced"
        @unknown default: return "unknown"
        }
    }
}

// MARK: - Location Streamer (continuous updates)

@MainActor
private final class LocationStreamer: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let onUpdate: @MainActor (CLLocation) -> Void

    init(onUpdate: @escaping @MainActor (CLLocation) -> Void) {
        self.onUpdate = onUpdate
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func start() {
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.onUpdate(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

// MARK: - One-shot sampler (used by collect)

@MainActor
final class LocationSampler: NSObject, CLLocationManagerDelegate {
    static let shared = LocationSampler()

    private let manager = CLLocationManager()
    private var pending: [CheckedContinuation<CLLocation?, Never>] = []
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func sampleLocation() async -> CLLocation? {
        if let current = manager.location { return current }
        return await withCheckedContinuation { continuation in
            let shouldStart = pending.isEmpty
            pending.append(continuation)
            if shouldStart {
                manager.requestLocation()
                timeoutTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    self?.resolve(nil)
                }
            }
        }
    }

    private func resolve(_ location: CLLocation?) {
        guard !pending.isEmpty else { return }
        let continuations = pending
        pending.removeAll()
        timeoutTask?.cancel()
        timeoutTask = nil
        for continuation in continuations {
            continuation.resume(returning: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let first = locations.first
        Task { @MainActor in self.resolve(first) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.resolve(nil) }
    }
}
