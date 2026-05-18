//
//  ISDColors.swift
//  ISDStockDashboard
//

import SwiftUI

// MARK: - India Stock Dashboard Color System
// Source: Design System — dark terminal theme
// https://github.com/pratikopenclaw-ship-it/Stock-Dashboard-app

extension Color {
    static let isdBackground = Color(hex: "#0B1120")
    static let isdBackgroundSecondary = Color(hex: "#111827")
    static let isdBackgroundTertiary = Color(hex: "#0F172A")
    static let isdCard = Color(hex: "#1E293B")
    static let isdElevated = Color(hex: "#243042")

    static let isdAccent = Color(hex: "#3B82F6")
    static let isdAccentLight = Color(hex: "#60A5FA")
    static let isdAccentDark = Color(hex: "#2563EB")

    static let isdGreen = Color(hex: "#10B981")
    static let isdGreenLight = Color(hex: "#34D399")
    static let isdGreenDark = Color(hex: "#059669")

    static let isdRed = Color(hex: "#EF4444")
    static let isdRedLight = Color(hex: "#F87171")
    static let isdRedDark = Color(hex: "#DC2626")

    static let isdGold = Color(hex: "#F59E0B")
    static let isdPurple = Color(hex: "#8B5CF6")
    static let isdPink = Color(hex: "#EC4899")

    static let isdTextPrimary = Color(hex: "#F1F5F9")
    static let isdTextSecondary = Color(hex: "#94A3B8")
    static let isdTextMuted = Color(hex: "#64748B")

    static let isdBorder = Color(hex: "#334155")
    static let isdBorderHover = Color(hex: "#475569")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Semantic Helpers

extension Color {
    static func profitLossColor(_ value: Double) -> Color {
        if value > 0 { return .isdGreen }
        if value < 0 { return .isdRed }
        return .isdAccent
    }
}
