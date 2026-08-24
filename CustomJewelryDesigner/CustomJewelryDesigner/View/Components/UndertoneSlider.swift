//
//  UndertoneSlider.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 24/08/26.
//

import SwiftUI

struct UndertoneSliderView: View {
    @Binding var color: Color
    var onCommit: (Color) -> Void = { _ in }

    @State private var undertone: CGFloat = 0.5
    @State private var isDragging = false

    private let coolHueRaw: Double = -0.03
    private let warmHueRaw: Double = 0.08

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Undertone")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                let usableWidth: CGFloat = max(1, geo.size.width - 26)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [coolColor, warmColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 14)

                    thumb
                        .offset(x: undertone * usableWidth)
                }
                .frame(height: 26)
                .contentShape(Rectangle())
                .gesture(dragGesture(usableWidth: usableWidth))
            }
            .frame(height: 26)

            HStack {
                Text("Warm").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("Cool").font(.caption).foregroundStyle(.secondary)
            }
        }
        .onAppear { sync(from: color) }
        .onChange(of: color) { _, newValue in
            guard !isDragging else { return }
            sync(from: newValue)
        }
    }

    private var currentHue: Double {
        let t = Double(undertone)
        let h = coolHueRaw + (warmHueRaw - coolHueRaw) * t
        return h < 0 ? h + 1 : h
    }

    private var coolColor: Color {
        let h = coolHueRaw < 0 ? coolHueRaw + 1 : coolHueRaw
        return Color(hue: h, saturation: 0.4, brightness: 0.6)
    }

    private var warmColor: Color {
        Color(hue: warmHueRaw, saturation: 0.55, brightness: 0.65)
    }

    private var thumb: some View {
        Circle()
            .strokeBorder(.white, lineWidth: 3)
            .background(Circle().fill(Color(hue: currentHue, saturation: 0.5, brightness: 0.65)))
            .frame(width: 26, height: 26)
            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
    }

    private func dragGesture(usableWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                let x: CGFloat = min(max(0, value.location.x - 13), usableWidth)
                undertone = usableWidth == 0 ? 0 : x / usableWidth
                push()
            }
            .onEnded { _ in
                isDragging = false
                onCommit(color)
            }
    }

    private func push() {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        color = Color(hue: currentHue, saturation: Double(s), brightness: Double(b))
    }

    private func sync(from newColor: Color) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(newColor).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        var hue = Double(h)
        if hue > 0.5 { hue -= 1 }
        let t = (hue - coolHueRaw) / (warmHueRaw - coolHueRaw)
        undertone = CGFloat(max(0, min(1, t)))
    }
}
