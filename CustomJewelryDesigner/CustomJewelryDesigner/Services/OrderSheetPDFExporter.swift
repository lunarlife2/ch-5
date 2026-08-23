//
//  OrderSheetPDFExporter.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 23/08/26.
//

import Foundation
import UIKit

enum OrderSheetPDFExporter {

    static func makePDF(for designFile: DesignFile) -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let safeName = designFile.name.replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeName)_OrderSheet.pdf")

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                var cursorY: CGFloat = margin

                drawText("KILAU", at: CGPoint(x: margin, y: cursorY), font: .boldSystemFont(ofSize: 20))
                cursorY += 26
                drawText("CUSTOMIZATION ORDER SHEET", at: CGPoint(x: margin, y: cursorY), font: .systemFont(ofSize: 10), color: .secondaryLabel)
                cursorY += 20

                let dividerPath = UIBezierPath()
                dividerPath.move(to: CGPoint(x: margin, y: cursorY))
                dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: cursorY))
                UIColor.separator.setStroke()
                dividerPath.stroke()
                cursorY += 24

                drawText(designFile.name, at: CGPoint(x: margin, y: cursorY), font: .boldSystemFont(ofSize: 18))
                cursorY += 22
                let subtitle = "Custom Engagement Ring . Created Date: \(designFile.createdAt.formatted(date: .long, time: .omitted))"
                drawText(subtitle, at: CGPoint(x: margin, y: cursorY), font: .systemFont(ofSize: 11), color: .secondaryLabel)
                cursorY += 30

                let mainImageSize = CGSize(width: 200, height: 200)
                if let mainImage = image(from: designFile.thumbnailData) {
                    mainImage.draw(in: CGRect(origin: CGPoint(x: margin, y: cursorY), size: mainImageSize))
                }

                let thumbSize: CGFloat = 80
                let thumbSpacing: CGFloat = 12
                let thumbStartX = margin + mainImageSize.width + 24
                let angles: [(String, Data?)] = [
                    ("Front", designFile.thumbnailData),
                    ("Back", designFile.backImageData),
                    ("Right", designFile.rightImageData),
                    ("Left", designFile.leftImageData)
                ]

                for (index, angle) in angles.enumerated() {
                    let col = index % 2
                    let row = index / 2
                    let x = thumbStartX + CGFloat(col) * (thumbSize + thumbSpacing)
                    let y = cursorY + CGFloat(row) * (thumbSize + 24)
                    if let img = image(from: angle.1) {
                        img.draw(in: CGRect(x: x, y: y, width: thumbSize, height: thumbSize))
                    } else {
                        UIColor.systemGray5.setFill()
                        UIBezierPath(rect: CGRect(x: x, y: y, width: thumbSize, height: thumbSize)).fill()
                    }
                    drawText(angle.0, at: CGPoint(x: x, y: y + thumbSize + 4), font: .systemFont(ofSize: 9), color: .secondaryLabel)
                }

                cursorY += mainImageSize.height + 30

                drawText("What You Chose", at: CGPoint(x: margin, y: cursorY), font: .boldSystemFont(ofSize: 14))
                cursorY += 22

                let rows: [(String, String)] = [
                    ("Metal", designFile.design?.materialPreset ?? "-"),
                    ("Gem", designFile.design?.gems.map { $0.name }.joined(separator: ", ") ?? "-"),
                    ("Band Thickness", designFile.design?.band?.thickness?.capitalized ?? "-"),
                    ("Ring Size", ringSizeText(for: designFile))
                ]

                for row in rows {
                    drawText(row.0, at: CGPoint(x: margin, y: cursorY), font: .systemFont(ofSize: 10), color: .secondaryLabel)
                    drawText(row.1, at: CGPoint(x: margin + 140, y: cursorY), font: .boldSystemFont(ofSize: 11))
                    cursorY += 18
                }

                cursorY += 16
                drawText("Your Notes", at: CGPoint(x: margin, y: cursorY), font: .boldSystemFont(ofSize: 12))
                cursorY += 18

                let notesRect = CGRect(x: margin, y: cursorY, width: pageWidth - margin * 2, height: 70)
                UIColor.separator.setStroke()
                UIBezierPath(roundedRect: notesRect, cornerRadius: 8).stroke()
                if let notes = designFile.notes, !notes.isEmpty {
                    drawText(notes, at: CGPoint(x: margin + 10, y: cursorY + 10), font: .systemFont(ofSize: 10), width: notesRect.width - 20)
                }

                let footerY = pageHeight - margin
                drawText("Ring jewelry. Confidential Specification", at: CGPoint(x: margin, y: footerY - 12), font: .systemFont(ofSize: 8), color: .secondaryLabel)
                drawText("Page 1 of 1", at: CGPoint(x: pageWidth - margin - 60, y: footerY - 12), font: .systemFont(ofSize: 8), color: .secondaryLabel)
            }
            return url
        } catch {
            print("OrderSheetPDFExporter: failed to write PDF: \(error)")
            return nil
        }
    }

    private static func ringSizeText(for designFile: DesignFile) -> String {
        guard let id = designFile.design?.ringSizeID,
              let option = ringSizeOptions.first(where: { $0.id == id }) else {
            return "-"
        }
        return "US size \(option.usCanada)"
    }

    private static func image(from data: Data?) -> UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }

    private static func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .label, width: CGFloat? = nil) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)

        if let width {
            attributedText.draw(with: CGRect(x: point.x, y: point.y, width: width, height: 200), options: .usesLineFragmentOrigin, context: nil)
        } else {
            attributedText.draw(at: point)
        }
    }
}
