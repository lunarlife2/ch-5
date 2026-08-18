//
//  GestureComponent.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 07/08/26.
//

import RealityKit
import SwiftUI

public enum JewelryEditorType: String, Codable {
    case band
    case gemstone
    case handMannequin
}

public struct GestureComponent: Component, Codable {
    public var typeJewelry: JewelryEditorType
    
    public var canDrag: Bool
    public var canScale: Bool
    public var canRotate: Bool
    
    public init(typeJewelry: JewelryEditorType, canDrag: Bool = true, canScale: Bool = true, canRotate: Bool = true) {
        self.typeJewelry = typeJewelry
        self.canDrag = canDrag
        self.canScale = canScale
        self.canRotate = canRotate
    }
    
}
