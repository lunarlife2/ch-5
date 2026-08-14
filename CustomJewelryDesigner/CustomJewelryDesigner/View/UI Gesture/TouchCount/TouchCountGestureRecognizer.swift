//
//  TouchCountGestureRecognizer.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 13/08/26.
//
import SwiftUI
import UIKit

final class TouchCountGestureRecognizer: UIGestureRecognizer {
    weak var tracker: TouchCountViewModel?
 
    private func liveCount(_ event: UIEvent?) -> Int {
        (event?.allTouches ?? []).filter {
            $0.phase != .ended && $0.phase != .cancelled
        }.count
    }
 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        tracker?.update(liveCount(event))
        state = .changed
    }
 
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        state = .changed
    }
 
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        let count = liveCount(event)
        tracker?.update(count)
        state = count == 0 ? .ended : .changed
    }
 
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        tracker?.update(0)
        state = .cancelled
    }
}
 
