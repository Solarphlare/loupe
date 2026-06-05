//
//  Compatibility.swift
//  Loupe
//
//  Compatibility wrappers for newer SwiftUI APIs so feature views can
//  keep using one call site while preserving older OS support.
//

import SwiftUI

extension View {
    @ViewBuilder
    func compatibleBorderedButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    func compatibleProminentButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    func compatibleRotateSymbolEffect<Value: Equatable>(value: Value) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            symbolEffect(.rotate, value: value)
        } else {
            self
        }
    }

    @ViewBuilder
    func compatibleScrollEdgeStyleSoft() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            self
        }
    }
}
