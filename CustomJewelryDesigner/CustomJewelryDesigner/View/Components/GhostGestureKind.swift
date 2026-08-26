//
//  GhostGestureKind.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//
import SwiftUI

import SwiftUI

enum GhostGestureKind {
    case rotate
    case pinch
    case drag(from: CGPoint, to: CGPoint)
    case tap
}

struct GhostGestureHint: View {

    let kind: GhostGestureKind
    let anchor: CGPoint

    var body: some View {
        TimelineView(.animation) { timeline in

            let progress = animationProgress(
                time: timeline.date.timeIntervalSinceReferenceDate
            )

            ZStack {

                switch kind {

                case .rotate:
                    fingerprint
                        .offset(
                            orbitOffset(
                                radius: 30,
                                progress: progress
                            )
                        )
                        .rotationEffect(
                            .degrees(progress * 360)
                        )

                case .pinch:
                    pinchGesture(progress: progress)

                case .drag(let from, let to):
                    fingerprint
                        .offset(
                            x: from.x + (to.x - from.x) * progress,
                            y: from.y + (to.y - from.y) * progress
                        )

                case .tap:
                    fingerprint
                        .scaleEffect(
                            1 - progress * 0.15
                        )
                        .opacity(
                            1 - progress * 0.4
                        )
                }
            }
        }
        .position(anchor)
    }

    private var fingerprint: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.appFont(size: 44))
            .foregroundStyle(.white)
            .shadow(radius: 6)
    }

    private func pinchGesture(progress: CGFloat) -> some View {
        ZStack {
            fingerprint
                .offset(x: -pinchDistance(progress: progress))

            fingerprint
                .scaleEffect(x: -1, y: 1)
                .offset(x: pinchDistance(progress: progress))
        }
    }

    private func pinchDistance(progress: CGFloat) -> CGFloat {
        8 + progress * 32
    }

    private func animationProgress(time: TimeInterval) -> CGFloat {
        let duration = 1.4
        let elapsed = time.truncatingRemainder(
            dividingBy: duration * 2
        )

        let normalized: Double

        if elapsed <= duration {
            normalized = elapsed / duration
        } else {
            normalized = 2 - elapsed / duration
        }

        return CGFloat(normalized)
    }

    private func orbitOffset(
        radius: CGFloat,
        progress: CGFloat
    ) -> CGSize {

        let angle = progress * 2 * .pi

        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }
}

private extension GhostGestureKind {

    var isBackAndForth: Bool {

        switch self {
        case .pinch, .drag, .tap:
            return true

        case .rotate:
            return false
        }
    }
}
