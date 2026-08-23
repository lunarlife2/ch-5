//
//  SkinToneCameraResultView.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 21/08/26.
//

import SwiftUI
import UIKit

struct SkinToneCameraResultView: View {

    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    var onRetake: () -> Void
    var onApply: (Color) -> Void

    @State private var samplePoint = CGPoint(x: 0.5, y: 0.42)
    @State private var isDraggingSampler = false
    @State private var color: Color = SkinColorDefault.color

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                GeometryReader { geo in
                    HStack(alignment: .top, spacing: 24) {
                        photoWithSampler(containerSize: geo.size)
                            .frame(maxWidth: .infinity)

                        colorPanel
                            .frame(width: 280)
                    }
                    .padding(20)
                }

                footer
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear { sample(at: samplePoint) }
        }
    }

    private var header: some View {
        HStack {
            Button {
                onRetake()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)

            VStack(alignment: .leading, spacing: 2) {
                Text("Match My Skin Tone")
                    .font(.system(size: 17, weight: .semibold))

                Text("Drag selector to a flat, well-lit area of your skin. Avoid heavy shadows or bright highlights.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(isDraggingSampler ? "Sampling…" : "Release to sample")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func photoWithSampler(containerSize: CGSize) -> some View {
        GeometryReader { geo in
            let frame = imageDisplayFrame(in: geo.size)

            ZStack(alignment: .topLeading) {
                Color(.secondarySystemBackground)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                sampler
                    .position(
                        x: frame.minX + samplePoint.x * frame.width,
                        y: frame.minY + samplePoint.y * frame.height
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDraggingSampler = true
                                let x = min(max(frame.minX, value.location.x), frame.maxX)
                                let y = min(max(frame.minY, value.location.y), frame.maxY)
                                samplePoint = CGPoint(
                                    x: frame.width == 0 ? 0.5 : (x - frame.minX) / frame.width,
                                    y: frame.height == 0 ? 0.5 : (y - frame.minY) / frame.height
                                )
                                sample(at: samplePoint)
                            }
                            .onEnded { _ in isDraggingSampler = false }
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var sampler: some View {
        VStack(spacing: 6) {
            Text("#\(color.hexString)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.6))
                .foregroundStyle(.white)
                .clipShape(Capsule())

            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                Circle()
                    .strokeBorder(.white, lineWidth: 3)
                    .frame(width: 44, height: 44)
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
        .offset(y: -26)
    }

    private func imageDisplayFrame(in containerSize: CGSize) -> CGRect {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0
        else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let containerAspect = containerSize.width / containerSize.height
        let imageAspect = imageSize.width / imageSize.height

        if imageAspect > containerAspect {
            let width = containerSize.width
            let height = width / imageAspect
            let y = (containerSize.height - height) / 2
            return CGRect(x: 0, y: y, width: width, height: height)
        } else {
            let height = containerSize.height
            let width = height * imageAspect
            let x = (containerSize.width - width) / 2
            return CGRect(x: x, y: 0, width: width, height: height)
        }
    }

    private func sample(at normalizedPoint: CGPoint) {
        guard let uiColor = UIColor.averageColor(in: image, atNormalizedPoint: normalizedPoint) else { return }
        color = Color(uiColor)
    }

    private var colorPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Color")
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.black.opacity(0.1)))

                    Text("#\(color.hexString)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }

                Text("Shade & Depth")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                ShadeDepthPickerView(color: $color)
                    .frame(height: 150)

                UndertoneSliderView(color: $color)


                RecentlyMatchedRow(selectedColor: color) { picked in
                    color = picked
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                onRetake()
            } label: {
                Label("Retake", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.glass)

            Spacer()

            Button {
                RecentSkinColorStore.shared.record(color)
                onApply(color)
            } label: {
                Label("Apply", systemImage: "checkmark")
            }
            .buttonStyle(.glassProminent)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, 8)
    }
}
