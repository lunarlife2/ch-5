//
//  SkinToneCameraSession.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 21/08/26.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

@Observable
final class SkinToneCameraSession: NSObject {
    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "skin-tone-camera-session")

    var isAuthorized = false
    var capturedImage: UIImage?
    private var captureCompletion: ((UIImage?) -> Void)?

    func requestAccessAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.configureAndStart() }
                }
            }
        default:
            isAuthorized = false
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
            }
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in self?.captureSession.stopRunning() }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension SkinToneCameraSession: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            captureCompletion?(nil); captureCompletion = nil; return
        }
        let normalized = image.normalizedOrientation()
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = normalized
            self?.captureCompletion?(normalized)
            self?.captureCompletion = nil
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
