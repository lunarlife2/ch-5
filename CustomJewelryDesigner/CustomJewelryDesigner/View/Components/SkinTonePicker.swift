//
//  SkinTonePickerView.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 24/08/26.
//

import SwiftUI

struct SkinTonePickerView: View {
    @Binding var color: Color
    var onCommit: (Color) -> Void = { _ in }
    var showShadeDepth: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showShadeDepth {
                Text("Shade & Depth")
                    .font(.appFont(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                ShadeDepthPickerView(color: $color, onCommit: onCommit)
                    .frame(height: 150)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }

            UndertoneSliderView(color: $color, onCommit: onCommit)
        }
    }
}
