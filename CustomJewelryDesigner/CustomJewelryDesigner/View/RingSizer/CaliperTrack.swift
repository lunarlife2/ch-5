//
//  CaliperTrack.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 23/08/26.
//

import SwiftUI

struct CaliperTrack: View {
    let hand: Hand
    let separationPoints: CGFloat
    let minSeparation: CGFloat
    let maxSeparation: CGFloat
    let onDrag: (CGFloat) -> Void

    private let cornerRadius: CGFloat = 20
    private var blueOnRight: Bool { hand == .left }
    private let dragActivationDistance: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let gapWidth = min(max(separationPoints, minSeparation), maxSeparation)
            let blueWidth = max(trackWidth - gapWidth, 0)

            ZStack(alignment: blueOnRight ? .trailing : .leading) {
                Rectangle()
                    .fill(Color(uiColor: .systemGray6))
                    .frame(height: 294)
                    .overlay(alignment: blueOnRight ? .leading : .trailing) {
                        Text("Rest your \nfinger\nagainst \nthe ledge")
                            .font(.caption)
                            .padding(.horizontal, 2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(width: max(trackWidth - blueWidth, 0))
                            .opacity(trackWidth - blueWidth > 50 ? 1 : 0)
                    }

                Capsule()
                    .fill(Color(uiColor: .systemGray3))
                    .frame(width: 20, height: 313)
                    .shadow(radius: 10)
                    .position(
                        x: blueOnRight ? -10 : 360,
                        y: 160
                    )

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.accentColor)
                    .frame(width: blueWidth)
                    .shadow(radius: 10, y: 10)
                    .overlay(alignment: blueOnRight ? .topTrailing : .topLeading) {
                        Image(systemName: "arrow.left.and.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(10)
                    }
                    .overlay(alignment: .bottom) {
                        Label(
                            "Drag until it fits snugly",
                            systemImage: "arrow.left.and.right"
                        )
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.bottom, 16)
                    }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: dragActivationDistance)
                    .onChanged { value in
                        let x = value.location.x

                        let newSeparation = blueOnRight
                            ? x
                            : (trackWidth - x)

                        onDrag(newSeparation)
                    }
            )
        }
    }
}
