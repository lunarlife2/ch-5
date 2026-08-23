//
//  RecentlyMatchedRow.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 21/08/26.
//

import SwiftUI

struct RecentlyMatchedRow: View {
    @Bindable var store: RecentSkinColorStore = .shared
    var selectedColor: Color
    var onSelect: (Color) -> Void

    private let slotCount = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently Matched")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(0..<slotCount, id: \.self) { index in
                    swatch(at: index)
                }
            }
        }
    }

    @ViewBuilder
    private func swatch(at index: Int) -> some View {
        if index < store.recentColors.count {
            let recentColor = store.recentColors[index]
            Button { onSelect(recentColor) } label: {
                Circle()
                    .fill(recentColor)
                    .overlay(Circle().strokeBorder(
                        isSelected(recentColor) ? Color.accentColor : Color.black.opacity(0.08),
                        lineWidth: isSelected(recentColor) ? 2 : 1
                    ))
            }
            .buttonStyle(.plain)
            .frame(width: 30, height: 30)
        } else {
            Circle().fill(Color(.systemGray5)).frame(width: 30, height: 30)
        }
    }

    private func isSelected(_ color: Color) -> Bool {
        color.hexString == selectedColor.hexString
    }
}
