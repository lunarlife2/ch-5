//
//  BandAxisHelper.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 21/08/26.
//

import Foundation

private enum CanonicalAxis {
    case x
    case y
    case z
}

private func smallestAxis(of extents: SIMD3<Float>) -> CanonicalAxis {
    if extents.x <= extents.y && extents.x <= extents.z {
        return .x
    } else if extents.y <= extents.x && extents.y <= extents.z {
        return .y
    } else {
        return .z
    }
}
