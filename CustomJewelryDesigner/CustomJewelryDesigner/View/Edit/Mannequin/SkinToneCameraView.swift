//
//  SkinToneCameraView.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 21/08/26.
//

import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

struct SkinToneCameraView: View {

    @Environment(\.dismiss) private var dismiss

    var onFinish: (Color) -> Void

    @State private var session = SkinToneCameraSession()
    @State private var showTips = true

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showResult = false

    @State private var torchOn = false
    @State private var gridOn = false

    var body: some View {
        NavigationStack {
            ZStack {
                cameraLayer

                VStack {
                    topBar
                    Spacer()
                    HStack(alignment: .bottom) {
                        tipsCard
                        Spacer()
                        sideControls
                    }
                    .padding(.bottom, 24)
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .task { session.requestAccessAndStart() }
            .onDisappear { session.stop() }
            .onChange(of: photoPickerItem) { _, newItem in
                Task { await loadGalleryImage(newItem) }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let capturedImage {
                    SkinToneCameraResultView(
                        image: capturedImage,
                        onRetake: {
                            self.capturedImage = nil
                            showResult = false
                        },
                        onApply: { color in
                            onFinish(color)
                            showResult = false
                            dismiss()
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var cameraLayer: some View {
        if session.isAuthorized {
            CameraPreviewView(session: session.captureSession)
                .ignoresSafeArea()
                .overlay {
                    if gridOn { gridOverlay }
                }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                Text("Camera access is needed to match your skin tone.")
                    .multilineTextAlignment(.center)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(40)
        }
    }

    private var gridOverlay: some View {
        GeometryReader { geo in
            Path { path in
                for i in 1..<3 {
                    let x = geo.size.width * CGFloat(i) / 3
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))

                    let y = geo.size.height * CGFloat(i) / 3
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.4), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.35))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)

            Spacer()

            Text("Match My Skin Tone")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.black.opacity(0.35))
                .clipShape(Capsule())

            Spacer()

            // balances the back button so the title stays centered
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private var tipsCard: some View {
        if showTips {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tips")
                            .font(.system(size: 15, weight: .semibold))
                        Text("For the most accurate results")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        withAnimation { showTips = false }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                tipRow(icon: "sun.max.fill", title: "Natural light", subtitle: "Daylight works best")
                tipRow(icon: "rectangle.fill", title: "Plain background", subtitle: "Use a neutral surface")
                tipRow(icon: "bolt.slash.fill", title: "Turn off flash", subtitle: "Avoid color distortion")
            }
            .padding(16)
            .frame(width: 220)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .transition(.opacity.combined(with: .move(edge: .leading)))
        } else {
            Button {
                withAnimation { showTips = true }
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.35))
                    .clipShape(Circle())
            }
        }
    }

    private func tipRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 18)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sideControls: some View {
        VStack(spacing: 18) {
            controlDot(icon: torchOn ? "bolt.fill" : "bolt.slash.fill") {
                torchOn.toggle()
                setTorch(on: torchOn)
            }

            controlDot(icon: gridOn ? "grid" : "square") {
                gridOn.toggle()
            }

            Spacer().frame(height: 4)

            // Shutter
            Button {
                session.capturePhoto { image in
                    guard let image else { return }
                    capturedImage = image
                    showResult = true
                }
            } label: {
                Circle()
                    .fill(.white)
                    .frame(width: 62, height: 62)
                    .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 3).frame(width: 72, height: 72))
            }

            // Gallery picker
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                galleryThumbnail
            }
        }
    }

    private func controlDot(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var galleryThumbnail: some View {
        if let capturedImage {
            Image(uiImage: capturedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        } else {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
        }
    }

    private func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    private func loadGalleryImage(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }

        await MainActor.run {
            capturedImage = image
            showResult = true
        }
    }
}
