//
//  GizmoHandle.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 18/08/26.
//

import Foundation

enum GizmoHandle: Equatable {
    case xAxis
    case yAxis
    case zAxis
    
    case xRotation
    case yRotation
    case zRotation
    
    case xScale
    case yScale
    case zScale
    
    case uniformScale
    
    var axis: SIMD3<Float>? {
        switch self {
        case .xAxis, .xRotation, .xScale:
            return SIMD3<Float>(1, 0, 0)
            
        case .yAxis, .yRotation, .yScale:
            return SIMD3<Float>(0, 1, 0)
            
        case .zAxis, .zRotation, .zScale:
            return SIMD3<Float>(0, 0, 1)
            
        case .uniformScale:
            return nil
        }
    }
    
    var isTranslation: Bool {
        switch self {
        case .xAxis, .yAxis, .zAxis:
            return true
            
        default:
            return false
        }
    }
}
