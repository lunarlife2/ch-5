//
//  SpotlightOverlay.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//

import SwiftUI

struct SpotlightMask: Shape {
    var targetFrame: CGRect?
    var cornerRadius: CGFloat
    var padding: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        if let targetFrame {
            let cutout = CGRect(
                x: targetFrame.minX - padding,
                y: targetFrame.minY - padding,
                width: targetFrame.width + padding * 2,
                height: targetFrame.height + padding * 2
            )
            path.addRoundedRect(
                in: cutout,
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
            )
        }
        return path
    }
}

struct SpotlightOverlay<Card: View>: View {
    var targetFrame: CGRect?
    var cutoutCornerRadius: CGFloat = 50
    var cutoutPadding: CGFloat = 8
    var onBackgroundTap: (() -> Void)? = nil
    @ViewBuilder var card: () -> Card

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.55)
                    .overlay {
                        if let targetFrame {
                            RoundedRectangle(cornerRadius: cutoutCornerRadius)
                                .frame(
                                    width: targetFrame.width + cutoutPadding * 2,
                                    height: targetFrame.height + cutoutPadding * 2
                                )
                                .position(x: targetFrame.midX, y: targetFrame.midY)
                                .blendMode(.destinationOut)
                        }
                    }
                    .compositingGroup()
                    .ignoresSafeArea()
                    .contentShape(
                        SpotlightMask(
                            targetFrame: targetFrame,
                            cornerRadius: cutoutCornerRadius,
                            padding: cutoutPadding
                        ),
                        eoFill: true
                    )
                    .onTapGesture { onBackgroundTap?() }

                card()
                    .position(cardPosition(in: proxy.size))
            }
        }
    }

    private func cardPosition(in size: CGSize) -> CGPoint {
        guard let targetFrame else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        let preferredY = targetFrame.minY - 140
        let y = preferredY > 100 ? preferredY : min(targetFrame.maxY + 140, size.height - 100)
        let x = min(max(targetFrame.midX, 220), size.width - 220)
        return CGPoint(x: x, y: y)
    }
}
