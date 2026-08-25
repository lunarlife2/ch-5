//
//  ShadeDepthPicker.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 24/08/26.
//

import SwiftUI

struct ShadeDepthPickerView: View {
    @Binding var color: Color
    var onCommit: (Color) -> Void = { _ in }

    @State private var depth: CGFloat = 0.45
    @State private var chroma: CGFloat = 0.55
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width: CGFloat = geo.size.width
            let height: CGFloat = geo.size.height
            let hue = hue(of: color)

            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        Color(hue: hue, saturation: 0.15, brightness: 0.97),
                        Color(hue: hue, saturation: 0.85, brightness: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                thumb
                    .position(x: chroma * width, y: depth * height)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width, height: height, hue: hue))
        }
        .onAppear { sync(from: color) }
        .onChange(of: color) { _, newValue in
            guard !isDragging else { return }
            sync(from: newValue)
        }
    }

    private var thumb: some View {
        Circle()
            .strokeBorder(.white, lineWidth: 3)
            .background(Circle().fill(color))
            .frame(width: 26, height: 26)
            .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
    }

    private func dragGesture(width: CGFloat, height: CGFloat, hue: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                let x: CGFloat = min(max(0, value.location.x), width)
                let y: CGFloat = min(max(0, value.location.y), height)
                chroma = width == 0 ? 0 : x / width
                depth = height == 0 ? 0 : y / height
                push(hue: hue)
            }
            .onEnded { _ in
                isDragging = false
                onCommit(color)
            }
    }

    private func push(hue: Double) {
        let saturation = 0.15 + Double(chroma) * 0.70
        let brightness = 0.97 - Double(depth) * 0.82
        color = Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func sync(from newColor: Color) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(newColor).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        chroma = max(0, min(1, (s - 0.15) / 0.70))
        depth = max(0, min(1, (0.97 - b) / 0.82))
    }

    private func hue(of color: Color) -> Double {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Double(h)
    }
}
