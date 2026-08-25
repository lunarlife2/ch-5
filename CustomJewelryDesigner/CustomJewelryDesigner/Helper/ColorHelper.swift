//
//  ColorHelper.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 21/08/26.
//

import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        let r, g, b: Double
        if sanitized.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
        } else {
            r = 0.89; g = 0.72; b = 0.60
        }

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(
            format: "%02X%02X%02X",
            Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255))
        )
    }
}

extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension UIColor {
    static func averageColor(in image: UIImage, atNormalizedPoint point: CGPoint, sampleRadius: CGFloat = 14) -> UIColor? {
        let normalized = image.normalizedOrientation()
        guard let cgImage = normalized.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let centerX = Int(point.x * CGFloat(width))
        let centerY = Int(point.y * CGFloat(height))

        let radius = Int(sampleRadius)
        let minX = max(0, centerX - radius)
        let minY = max(0, centerY - radius)
        let maxX = min(width - 1, centerX + radius)
        let maxY = min(height - 1, centerY + radius)
        guard maxX > minX, maxY > minY else { return nil }

        let regionRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        guard let croppedCGImage = cgImage.cropping(to: regionRect) else { return nil }

        var pixelData = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(
            data: &pixelData, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .medium
        context.draw(croppedCGImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        return UIColor(
            red: CGFloat(pixelData[0]) / 255,
            green: CGFloat(pixelData[1]) / 255,
            blue: CGFloat(pixelData[2]) / 255,
            alpha: 1
        )
    }
}
