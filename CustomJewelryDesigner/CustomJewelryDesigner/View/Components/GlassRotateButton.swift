//
//  GlassRotateButton.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 20/08/26.
//

import SwiftUI

struct GlassRotateButton<Label: View>: View {

    private let onBegin: () -> Void
    private let onChanged: (Float) -> Void
    private let onEnded: () -> Void
    private let label: () -> Label

    @State private var lastAngle: CGFloat?

    private let buttonSize = CGSize(width: 30, height: 40)

    init(
        onBegin: @escaping () -> Void,
        onChanged: @escaping (Float) -> Void,
        onEnded: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.onBegin = onBegin
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
                    .frame(width: buttonSize.width, height: buttonSize.height)
            }
            .buttonStyle(.glassProminent)
            .tint(.white)
            .shadow(color: Color.shadowSecondary, radius: 0.25, x: 1.25)
            .shadow(color: Color.shadowSecondary, radius: 0.25, x: -1.25)
            .shadow(color: Color.shadowTertiary, radius: 0.5)
            .shadow(color: .black.opacity(0.02), radius: 15, y: 8)
            .allowsHitTesting(false)

            Color.clear
                .contentShape(Capsule())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            let center = CGPoint(x: buttonSize.width / 2, y: buttonSize.height / 2)
                            let dx = value.location.x - center.x
                            let dy = value.location.y - center.y

                            // hindari jitter kalau jari nyaris tepat di tengah tombol
                            guard hypot(dx, dy) > 4 else {
                                if lastAngle == nil { onBegin() }
                                return
                            }

                            let currentAngle = atan2(dy, dx)

                            if let last = lastAngle {
                                var delta = currentAngle - last
                                if delta > .pi { delta -= 2 * .pi }
                                if delta < -.pi { delta += 2 * .pi }
                                onChanged(Float(delta))
                            } else {
                                onBegin()
                            }

                            lastAngle = currentAngle
                        }
                        .onEnded { _ in
                            lastAngle = nil
                            onEnded()
                        }
                )
        }
        .frame(width: buttonSize.width, height: buttonSize.height)
    }
}
