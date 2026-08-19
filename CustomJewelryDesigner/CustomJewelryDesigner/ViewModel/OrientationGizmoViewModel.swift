//
//  OrientationGizmoViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 19/08/26.
//

import SwiftUI
import simd

struct AxisInfo {
    let axis: ViewAxis
    let title: String
    let color: Color
    let localVector: SIMD3<Float>
    let isPositive: Bool
}

struct ResolvedAxis {
    let info: AxisInfo
    let rotatedVector: SIMD3<Float>
    let screen: CGPoint
    let depth: Float
}

@Observable
final class OrientationGizmoViewModel {
    var dragStartLocation: CGPoint?
    var hoveredAxis: ViewAxis?
    var tapSnapOverride: simd_quatf?

    let size: CGFloat = 150

    let allAxes: [AxisInfo] = [
        AxisInfo(axis: .x, title: "X", color: .red,   localVector: SIMD3<Float>( 1, 0, 0), isPositive: true),
        AxisInfo(axis: .y, title: "Y", color: .green, localVector: SIMD3<Float>( 0, 1, 0), isPositive: true),
        AxisInfo(axis: .z, title: "Z", color: .blue,  localVector: SIMD3<Float>( 0, 0, 1), isPositive: true),
        AxisInfo(axis: .negativeX, title: "-X", color: .red,   localVector: SIMD3<Float>(-1, 0, 0), isPositive: false),
        AxisInfo(axis: .negativeY, title: "-Y", color: .green, localVector: SIMD3<Float>( 0,-1, 0), isPositive: false),
        AxisInfo(axis: .negativeZ, title: "-Z", color: .blue,  localVector: SIMD3<Float>( 0, 0,-1), isPositive: false),
    ]

    func displayOrientation(currentOrientation: simd_quatf) -> simd_quatf {
        tapSnapOverride ?? currentOrientation
    }

    func resolvedAxes(for orientation: simd_quatf) -> [ResolvedAxis] {
        let activeOrientation = displayOrientation(currentOrientation: orientation)
        
        return allAxes.map { info in
            let rotated = activeOrientation.act(info.localVector)
            return ResolvedAxis(
                info: info,
                rotatedVector: rotated,
                screen: project(rotated),
                depth: rotated.z
            )
        }
        .sorted { $0.depth < $1.depth }
    }

    func project(_ v: SIMD3<Float>) -> CGPoint {
        CGPoint(x: CGFloat(47 * v.x), y: CGFloat(-47 * v.y))
    }

    func offset(_ center: CGPoint, _ v: CGPoint) -> CGPoint {
        CGPoint(x: center.x + v.x, y: center.y + v.y)
    }

    func buttonPosition(_ v: CGPoint) -> CGPoint {
        CGPoint(x: size / 2 + v.x, y: size / 2 + v.y)
    }

    func calculateSnapOrientation(for axis: ViewAxis, currentOrientation: simd_quatf) -> simd_quatf {
        let currentDirection = currentOrientation.act(axis.worldVector)
        let targetDirection = SIMD3<Float>(0, 0, 1)
        let rot = simd_quatf.rotation(from: currentDirection, to: targetDirection)
        return rot * currentOrientation
    }
}
