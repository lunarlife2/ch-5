//
//  SnapPointComponent.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 15/08/26.
//

import Foundation
import RealityKit

public struct SnapPointComponent: Component, Codable {
    public var snapID: String
    public var index: Int
    public var localOrientationCorrection: simd_quatf
    public var standoffDistance: Float
    public var occupiedByGemName: String?

    public init(snapID: String, index: Int, localOrientationCorrection: simd_quatf = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(1, 0, 0)), standoffDistance: Float = 0.0001) {
        self.snapID = snapID
        self.index = index
        self.localOrientationCorrection = localOrientationCorrection
        self.standoffDistance = standoffDistance
        self.occupiedByGemName = nil
    }

    private enum CodingKeys: String, CodingKey {
        case snapID, index, standoffDistance, occupiedByGemName
        case orientX, orientY, orientZ, orientW
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        snapID = try c.decode(String.self, forKey: .snapID)
        index = try c.decode(Int.self, forKey: .index)
        standoffDistance = try c.decode(Float.self, forKey: .standoffDistance)
        occupiedByGemName = try c.decodeIfPresent(String.self, forKey: .occupiedByGemName)

        let x = try c.decode(Float.self, forKey: .orientX)
        let y = try c.decode(Float.self, forKey: .orientY)
        let z = try c.decode(Float.self, forKey: .orientZ)
        let w = try c.decode(Float.self, forKey: .orientW)
        localOrientationCorrection = simd_quatf(ix: x, iy: y, iz: z, r: w)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(snapID, forKey: .snapID)
        try c.encode(index, forKey: .index)
        try c.encode(standoffDistance, forKey: .standoffDistance)
        try c.encodeIfPresent(occupiedByGemName, forKey: .occupiedByGemName)

        try c.encode(localOrientationCorrection.imag.x, forKey: .orientX)
        try c.encode(localOrientationCorrection.imag.y, forKey: .orientY)
        try c.encode(localOrientationCorrection.imag.z, forKey: .orientZ)
        try c.encode(localOrientationCorrection.real, forKey: .orientW)
    }
}
