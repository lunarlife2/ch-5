//
//  SpotlightOverlay.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//

import SwiftUI

struct SpotlightOverlay<Card: View>: View {
    var targetFrame: CGRect?
    var cardPositionOverride: ((CGSize) -> CGPoint)? = nil
    var onBackgroundTap: (() -> Void)? = nil
    @ViewBuilder var card: () -> Card

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                card()
                    .position(cardPositionOverride?(proxy.size) ?? cardPosition(in: proxy.size))
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
