//
//  SignalProvider.swift
//  Loupe
//
//  Every fingerprinting surface is exposed through a single protocol.
//  Providers are MainActor-isolated by default so they can freely read
//  UIKit / AVFoundation state; providers that do real work off the main
//  thread wrap that work in their own actor and await the result.
//

import Foundation

@MainActor
protocol SignalProvider: Sendable {
    var category: SignalCategory { get }
    func collect() async -> [FingerprintSignal]
}

extension SignalProvider {
    var sensitivity: Sensitivity { category.sensitivity }
    var permission: PermissionKind? { category.permission }
}

@MainActor
protocol LiveSignalProvider: SignalProvider {
    var updateInterval: TimeInterval { get }
    func stream() -> AsyncStream<[FingerprintSignal]>
}
