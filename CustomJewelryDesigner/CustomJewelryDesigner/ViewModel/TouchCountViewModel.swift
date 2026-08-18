//
//  TouchCountTracker.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 13/08/26.
//

import SwiftUI
import UIKit
 
@Observable
final class TouchCountViewModel {
    private(set) var activeTouchCount: Int = 0
    func update(_ count: Int) {
        if activeTouchCount != count {
            print("[GESTURE] TOUCH COUNT ->", count)
        }
        activeTouchCount = count
    }
}
