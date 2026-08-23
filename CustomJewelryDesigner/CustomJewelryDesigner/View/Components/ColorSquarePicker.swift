//
//  ColorSquarePickerView.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 21/08/26.
//

import SwiftUI

struct ColorSquarePickerView: View {
    @Binding var color: Color

    @State private var hue: Double = 0.08
    @State private var saturation: Double = 0.45
    @State private var brightness: Double = 0.75
    @State private var isDraggingSquare = false
    @State private var isDraggingHue = false
    @State private var showEyedropper = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            saturationBrightnessSquare
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            hueRow
        }
        .onAppear { syncFromColor(color) }
        .onChange(of: color) { _, newValue in
            guard !isDraggingSquare, !isDraggingHue else { return }
            syncFromColor(newValue)
        }
        .background {
            if showEyedropper {
                EyedropperPresenter(
                    onPick: { picked in
                        color = Color(picked)
                        syncFromColor(Color(picked))
                    },
                    onDismiss: { showEyedropper = false }
                )
            }
        }
    }

    private var saturationBrightnessSquare: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color(hue: hue, saturation: 1, brightness: 1)
                LinearGradient(colors: [.white, .white.opacity(0)],
                               startPoint: .leading, endPoint: .trailing)
                LinearGradient(colors: [.black.opacity(0), .black],
                               startPoint: .top, endPoint: .bottom)

                selectorThumb
                    .position(x: saturation * geo.size.width,
                              y: (1 - brightness) * geo.size.height)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDraggingSquare = true
                        let x = min(max(0, value.location.x), geo.size.width)
                        let y = min(max(0, value.location.y), geo.size.height)
                        saturation = geo.size.width == 0 ? 0 : x / geo.size.width
                        brightness = geo.size.height == 0 ? 0 : 1 - (y / geo.size.height)
                        pushColor()
                    }
                    .onEnded { _ in isDraggingSquare = false }
            )
        }
    }

    private var selectorThumb: some View {
        Circle()
            .strokeBorder(.white, lineWidth: 3)
            .background(Circle().fill(color))
            .frame(width: 26, height: 26)
            .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
    }

    private var hueRow: some View {
        HStack(spacing: 10) {
            Button { showEyedropper = true } label: {
                Image(systemName: "eyedropper")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: rainbowColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 14)

                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .background(Circle().fill(Color(hue: hue, saturation: 1, brightness: 1)))
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                        .offset(x: hue * max(0, geo.size.width - 22))
                }
                .frame(height: 22)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingHue = true
                            let usableWidth = max(1, geo.size.width - 22)
                            let x = min(max(0, value.location.x - 11), usableWidth)
                            hue = x / usableWidth
                            pushColor()
                        }
                        .onEnded { _ in isDraggingHue = false }
                )
            }
            .frame(height: 22)
        }
    }

    private var rainbowColors: [Color] {
        stride(from: 0.0, through: 1.0, by: 1.0 / 36.0).map {
            Color(hue: $0, saturation: 1, brightness: 1)
        }
    }

    private func pushColor() {
        color = Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func syncFromColor(_ newColor: Color) {
        let uiColor = UIColor(newColor)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        hue = Double(h); saturation = Double(s); brightness = Double(b)
    }
}

private struct EyedropperPresenter: UIViewControllerRepresentable {
    var onPick: (UIColor) -> Void
    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard uiViewController.presentedViewController == nil, !context.coordinator.didPresent else { return }
        context.coordinator.didPresent = true

        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.delegate = context.coordinator
        DispatchQueue.main.async { uiViewController.present(picker, animated: true) }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick, onDismiss: onDismiss) }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        let onPick: (UIColor) -> Void
        let onDismiss: () -> Void
        var didPresent = false

        init(onPick: @escaping (UIColor) -> Void, onDismiss: @escaping () -> Void) {
            self.onPick = onPick; self.onDismiss = onDismiss
        }

        func colorPickerViewControllerDidSelectColor(_ vc: UIColorPickerViewController) {
            onPick(vc.selectedColor)
        }
        func colorPickerViewControllerDidFinish(_ vc: UIColorPickerViewController) {
            vc.dismiss(animated: true) { [weak self] in self?.onDismiss() }
        }
    }
}
