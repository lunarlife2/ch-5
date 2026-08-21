//
//  CaliperJaw.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 20/08/26.
//
import SwiftUI

struct CaliperJaws: View {
    @Binding var separation: CGFloat
    let trackWidth: CGFloat
    let minSeparation: CGFloat
    let maxSeparation: CGFloat

    @State private var leftDragStart: CGFloat?
    @State private var rightDragStart: CGFloat?

    var body: some View {
        ZStack {
            // Rail
            Capsule()
                .fill(.secondary.opacity(0.25))
                .frame(
                    width: trackWidth,
                    height: 4
                )

            // Left jaw
            jaw
                .offset(x: -separation / 2)
                .gesture(leftJawGesture)

            // Right jaw
            jaw
                .offset(x: separation / 2)
                .gesture(rightJawGesture)

            // Measurement line
            measurementLine
                .offset(x: 0)
        }
    }

    private var jaw: some View {
        VStack(spacing: 0) {

            Capsule()
                .fill(.primary)
                .frame(
                    width: 8,
                    height: 24
                )

            Rectangle()
                .fill(.primary)
                .frame(
                    width: 4,
                    height: 110
                )
        }
    }

    private var leftJawGesture: some Gesture {

        DragGesture(minimumDistance: 0)

            .onChanged { value in

                if leftDragStart == nil {
                    leftDragStart = separation
                }

                let start =
                    leftDragStart ?? separation

                let proposed =
                    start - value.translation.width * 2

                separation = min(
                    max(proposed, minSeparation),
                    maxSeparation
                )
            }

            .onEnded { _ in
                leftDragStart = nil
            }
    }

    private var rightJawGesture: some Gesture {

        DragGesture(minimumDistance: 0)

            .onChanged { value in

                if rightDragStart == nil {
                    rightDragStart = separation
                }

                let start =
                    rightDragStart ?? separation

                let proposed =
                    start + value.translation.width * 2

                separation = min(
                    max(proposed, minSeparation),
                    maxSeparation
                )
            }

            .onEnded { _ in
                rightDragStart = nil
            }
    }

    private var measurementLine: some View {

        Rectangle()
            .fill(.black)
            .frame(
                width: separation,
                height: 2
            )
    }
}
