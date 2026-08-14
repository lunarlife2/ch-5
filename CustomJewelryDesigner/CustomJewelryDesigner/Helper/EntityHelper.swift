//
//  EntityHelper.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 08/08/26.
//

import RealityKit
import SwiftUI

extension Entity {
    func gestureTarget() -> Entity? {
        var current: Entity? = self
        while let entity = current {
            if entity.components[GestureComponent.self] != nil {
                return entity
            }
            current = entity.parent
        }
        return nil
    }
}

public extension Entity {
    var gestureStateComponent: GestureStateComponent {
        get {
            components[GestureStateComponent.self] ?? GestureStateComponent()
        }
        set {
            components[GestureStateComponent.self] = newValue
        }
    }
}

