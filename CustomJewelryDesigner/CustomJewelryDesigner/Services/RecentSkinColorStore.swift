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
    private let maxCount = 8

    private(set) var recentHexColors: [String] = []

    private init() {
        recentHexColors = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }

    var recentColors: [Color] { recentHexColors.map { Color(hex: $0) } }

    func record(_ color: Color) {
        let hex = color.hexString
        recentHexColors.removeAll { $0 == hex }
        recentHexColors.insert(hex, at: 0)
        if recentHexColors.count > maxCount {
            recentHexColors = Array(recentHexColors.prefix(maxCount))
        }
        UserDefaults.standard.set(recentHexColors, forKey: storageKey)
    }
}
