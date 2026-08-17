//
//  TapRecognizer.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 15/08/26.
//
import UIKit

final class TapRecognizer: UIGestureRecognizer {
    private var startLocation: CGPoint = .zero
    private let tapMaxDistance: CGFloat = 10
    private(set) var tapLocation: CGPoint = .zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first, numberOfTouches == 1 else {
            state = .failed
            return
        }
        startLocation = touch.location(in: view)
        tapLocation = startLocation
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let loc = touch.location(in: view)
        let d = hypot(loc.x - startLocation.x, loc.y - startLocation.y)
        if d > tapMaxDistance {
            state = .failed
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else {
            state = .failed
            return
        }
        tapLocation = touch.location(in: view)
        state = .recognized
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        state = .failed
    }
}
