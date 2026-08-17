//
//  AttachmentComponent.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 15/08/26.
//

import RealityKit

public struct AttachmentComponent: Component, Codable {
    public var attachedSnapID: String?
    public var targetWorldScale: Float

    public init(attachedSnapID: String? = nil, targetWorldScale: Float = 0) {
        self.attachedSnapID = attachedSnapID
        self.targetWorldScale = targetWorldScale
    }
    
}
