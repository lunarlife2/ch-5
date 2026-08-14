//
//  TwoFingerTransformRecognizer.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 13/08/26.
//

import UIKit
import RealityKit
import SwiftUI
import Foundation

final class TwoFingerTransformRecognizer: UIGestureRecognizer {

    private var startCenter: CGPoint = .zero
    private var startDistance: CGFloat = 0

    private(set) var currentCenter: CGPoint = .zero
    private(set) var currentDistance: CGFloat = 0

    private(set) var panDelta: CGPoint = .zero
    private(set) var scaleDelta: CGFloat = 0

    override func reset() {
        super.reset()

        startCenter = .zero
        startDistance = 0

        currentCenter = .zero
        currentDistance = 0

        panDelta = .zero
        scaleDelta = 0
    }


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        let count = event.allTouches?.filter {
            $0.phase != .ended &&
            $0.phase != .cancelled
        }.count ?? 0

//        print("[2F] TOUCHES BEGAN", "count:", count)

        if count > 2 {
//            print("[2F] FAILED", "reason:more-than-2-fingers")
            state = .failed
            return
        }

        guard count == 2 else {
            return
        }

        guard let view else {
            state = .failed
            return
        }

        guard numberOfTouches == 2 else {
            return
        }

        let p1 = location(ofTouch: 0, in: view)

        let p2 = location(ofTouch: 1, in: view)

        let center = midpoint(p1, p2)

        let distance = distance(p1,p2)

        startCenter = center
        startDistance = distance

        currentCenter = center
        currentDistance = distance

        panDelta = .zero
        scaleDelta = 0

        print("[2F] TWO FINGERS READY", "center:", center, "distance:", distance)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        guard let view else {
            state = .failed
            return
        }

        let count = event.allTouches?.filter {
            $0.phase != .ended &&
            $0.phase != .cancelled
        }.count ?? 0

        if count > 2 {
//            print("[2F] FAILED", "reason:more-than-2-fingers")

            state = .failed
            return
        }
        guard count == 2 else {
            if state == .began || state == .changed {
                state = .ended
            } else {
                state = .failed
            }
            return
        }

        guard numberOfTouches == 2 else {
            return
        }

        let p1 = location( ofTouch: 0, in: view)

        let p2 = location(ofTouch: 1, in: view)

        let center = midpoint(p1, p2)

        let distance = distance(p1, p2)

        currentCenter = center
        currentDistance = distance

        panDelta = CGPoint(x: center.x - startCenter.x, y: center.y - startCenter.y)

        scaleDelta = distance - startDistance

        // First movement.
        if state == .possible {
            state = .began
        } else {
            state = .changed
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        let count = event.allTouches?.filter {
            $0.phase != .ended &&
            $0.phase != .cancelled
        }.count ?? 0

        print("[2F] TOUCHES ENDED", "remaining:", count)

        if state == .began || state == .changed {
            state = .ended
        } else {
            state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
//        print("[2F] TOUCHES CANCELLED")
        state = .cancelled
    }


    private func midpoint(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        CGPoint(
            x: (p1.x + p2.x) * 0.5,
            y: (p1.y + p2.y) * 0.5
        )
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
}




