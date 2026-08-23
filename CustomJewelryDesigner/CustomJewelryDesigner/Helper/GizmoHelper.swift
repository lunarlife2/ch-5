//
//  GizmoHelper.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 19/08/26.
//

import SwiftUI
import simd

enum ViewAxis: Hashable {
    case x, y, z
    case negativeX, negativeY, negativeZ

    var worldVector: SIMD3<Float> {
        switch self {
        case .x:         return SIMD3<Float>( 1,  0,  0)
        case .negativeX: return SIMD3<Float>(-1,  0,  0)
        case .y:         return SIMD3<Float>( 0,  1,  0)
        case .negativeY: return SIMD3<Float>( 0, -1,  0)
        case .z:         return SIMD3<Float>( 0,  0,  1)
        case .negativeZ: return SIMD3<Float>( 0,  0, -1)
        }
    }
}

extension simd_quatf {
    static func rotation(from a: SIMD3<Float>, to b: SIMD3<Float>) -> simd_quatf {
        let dot = simd_dot(simd_normalize(a), simd_normalize(b))

        if dot < -0.9999 {
            var axis = simd_cross(SIMD3<Float>(1, 0, 0), a)
            if simd_length(axis) < 1e-5 {
                axis = simd_cross(SIMD3<Float>(0, 1, 0), a)
            }
            return simd_quatf(angle: .pi, axis: simd_normalize(axis))
        }

        return simd_quatf(from: a, to: b)
    }
}
