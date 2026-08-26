//
//  GlassDragButton.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 20/08/26.
//

import SwiftUI

struct GlassScaleButton<Label: View>: View {

    private let onChanged: (DragGesture.Value) -> Void
    private let onEnded: (DragGesture.Value) -> Void
    private let label: () -> Label

    init(
        onChanged: @escaping (DragGesture.Value) -> Void,
        onEnded: @escaping (DragGesture.Value) -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.onChanged = onChanged
        self.onEnded = onEnded
        self.label = label
    }

    var body: some View {
        ZStack {
            Button {
            } label: {
                label()
                    .foregroundStyle(Color.black)
                    .font(.appFont(size: 27, weight: .medium))
                    .frame(width: 30, height: 40)
            }
            .buttonStyle(.glassProminent)
            .tint(.white)
            .shadow(
                color: Color.shadowSecondary,
                radius: 0.25,
                x: 1.25
            )
            .shadow(
                color: Color.shadowSecondary,
                radius: 0.25,
                x: -1.25
            )
            .shadow(
                color: Color.shadowTertiary,
                radius: 0.5
            )
            .shadow(
                color: .black.opacity(0.02),
                radius: 15,
                y: 8
            )
            .allowsHitTesting(false)

            // Gesture layer
            Color.clear
                .contentShape(Capsule())
                .gesture(
                    DragGesture(
                        minimumDistance: 0,
                        coordinateSpace: .local
                    )
                    .onChanged(onChanged)
                    .onEnded(onEnded)
                )
        }
        .frame(width: 30, height: 40)
    }
}
