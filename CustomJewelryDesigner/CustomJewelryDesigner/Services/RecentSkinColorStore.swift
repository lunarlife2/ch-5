//
//  RecentSkinColorStore.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 21/08/26.
//

import SwiftUI

enum SkinColorDefault {
    static let color = Color(hex: "C99668")
}

@Observable
final class RecentSkinColorStore {
    static let shared = RecentSkinColorStore()
    private let storageKey = "recentlyMatchedSkinColors"
    private let maxCount = 6

    private let similarityTolerance: Int = 10

    private(set) var recentHexColors: [String] = []

    private init() {
        recentHexColors = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }

    var recentColors: [Color] { recentHexColors.map { Color(hex: $0) } }

    func recentColors(excluding presets: [SkinColorPresets]) -> [Color] {
        let presetHexes = Set(presets.map { Color(hex: $0.color).hexString })
        return recentHexColors
            .filter { !presetHexes.contains($0) }
            .map { Color(hex: $0) }
    }

    func record(_ color: Color) {
        let hex = color.hexString
        guard let rgb = hexRGB(hex) else { return }

        recentHexColors.removeAll { existingHex in
            guard let existingRGB = hexRGB(existingHex) else { return false }
            return isSimilar(rgb, existingRGB)
        }

        recentHexColors.insert(hex, at: 0)
        if recentHexColors.count > maxCount {
            recentHexColors = Array(recentHexColors.prefix(maxCount))
        }
        UserDefaults.standard.set(recentHexColors, forKey: storageKey)
    }

    private func hexRGB(_ hex: String) -> (Int, Int, Int)? {
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return nil }
        return ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
    }

    private func isSimilar(_ a: (Int, Int, Int), _ b: (Int, Int, Int)) -> Bool {
        abs(a.0 - b.0) <= similarityTolerance &&
        abs(a.1 - b.1) <= similarityTolerance &&
        abs(a.2 - b.2) <= similarityTolerance
    }
}
