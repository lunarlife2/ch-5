//
//  OrientationGizmoView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 18/08/26.
//


import SwiftUI
import RealityKit
import simd

struct OrientationGizmoView: View {

    let orientation: simd_quatf
    @Binding var selectedAxis: ViewAxis?

    let onAxisSelected: (ViewAxis, simd_quatf) -> Void
    let onRotate: (CGFloat, CGFloat) -> Void
    let onRotateBegin: () -> Void
    let onRotateEnd: () -> Void

    @State private var viewModel = OrientationGizmoViewModel()
    @State private var suppressNextOrientationReset = false

    var body: some View {
        let currentResolvedAxes = viewModel.resolvedAxes(for: orientation)

        ZStack {
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                for resolved in currentResolvedAxes where resolved.info.isPositive {
                    drawAxis(
                        context: &context,
                        from: center,
                        to: viewModel.offset(center, resolved.screen),
                        color: resolved.info.color,
                        opacity: 1.0,
                        lineWidth: 3
                    )
                }
            }
            ForEach(currentResolvedAxes, id: \.info.axis) { resolved in
                let isSelected = selectedAxis == resolved.info.axis
                axisButton(
                    title: resolved.info.title,
                    axis: resolved.info.axis,
                    color: resolved.info.color,
                    position: viewModel.buttonPosition(resolved.screen),
                    opacity: isSelected || resolved.info.isPositive ? 1.0 : 0.35,
                    showLabelAlways: isSelected || resolved.info.isPositive
                )
            }
        }
        .frame(width: viewModel.size, height: viewModel.size)
        .background { Circle().fill(.ultraThinMaterial) }
        .clipShape(Circle())
        .overlay { Circle().stroke(.secondary.opacity(0.35), lineWidth: 1) }
        .gesture(dragGesture)
        .onChange(of: orientation) { _, _ in
            if suppressNextOrientationReset {
                suppressNextOrientationReset = false
                return
            }
            viewModel.tapSnapOverride = nil
            selectedAxis = nil
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if viewModel.dragStartLocation == nil {
                    viewModel.dragStartLocation = value.startLocation
                    viewModel.tapSnapOverride = nil
                    onRotateBegin()
                }
                let start = viewModel.dragStartLocation ?? value.startLocation
                onRotate(value.location.x - start.x, value.location.y - start.y)
            }
            .onEnded { _ in
                viewModel.dragStartLocation = nil
                onRotateEnd()
            }
    }

    private func handleAxisTap(_ axis: ViewAxis) {
        selectedAxis = axis

        let targetOrientation = viewModel.calculateSnapOrientation(
            for: axis,
            currentOrientation: orientation
        )

        suppressNextOrientationReset = true
        
        withAnimation(.easeOut(duration: 0.25)) {
            viewModel.tapSnapOverride = targetOrientation
        }

        onAxisSelected(axis, targetOrientation)
    }

    @ViewBuilder
    private func axisButton(title: String, axis: ViewAxis, color: Color, position: CGPoint, opacity: Double, showLabelAlways: Bool) -> some View {
        let isHovered = viewModel.hoveredAxis == axis
        let showLabel = showLabelAlways || isHovered

        Button {
            handleAxisTap(axis)
        } label: {
            ZStack {
                Circle().fill(color.opacity(isHovered ? min(opacity + 0.25, 1.0) : opacity))
                Circle().stroke(color.opacity(isHovered ? 1.0 : max(opacity, 0.45)), lineWidth: isHovered ? 2 : 1)
                if showLabel {
                    Text(title)
                        .font(.system(size: title.count > 1 ? 9 : 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: isHovered ? 30 : 26, height: isHovered ? 30 : 26)
            .shadow(color: color.opacity(isHovered ? 0.55 : 0.15), radius: isHovered ? 6 : 2)
            .animation(.easeOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .position(position)
        .onHover { hovering in
            viewModel.hoveredAxis = hovering ? axis : nil
        }
    }

    private func drawAxis(context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, opacity: Double, lineWidth: CGFloat) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lineWidth)
        let circleRect = CGRect(x: to.x - 4, y: to.y - 4, width: 8, height: 8)
        context.fill(Path(ellipseIn: circleRect), with: .color(color.opacity(opacity)))
    }
}
