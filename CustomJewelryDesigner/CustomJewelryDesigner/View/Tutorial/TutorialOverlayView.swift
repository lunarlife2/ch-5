//
//  TutorialOverlayView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//

import SwiftUI

struct TutorialOverlayView: View {

    var controller: TutorialController
    var tutorialViewModel: TutorialViewModel
    var onFinish: () -> Void

    var body: some View {
        GeometryReader { geometry in

            if let step = controller.currentStep {

                let frame = step.anchor.flatMap {
                    tutorialViewModel.frame(for: $0)
                }

                ZStack {

                    SpotlightOverlay(targetFrame: frame) {
                        card(for: step)
                    }

                    if let ghost = ghostKind(for: step) {

                        GhostGestureHint(
                            kind: ghost,
                            anchor: frame.map {
                                CGPoint(
                                    x: $0.midX,
                                    y: $0.midY
                                )
                            } ?? CGPoint(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                        )
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .transition(.opacity)
                .animation(.smooth, value: step)
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func card(for step: TutorialStep) -> some View {

        let content = info(for: step)

        CoachMarkCard(
            title: content.title,
            subtitle: content.text,
            stepInfo: stepNumber(for: step).map { ($0, 8) },
            onSkip: {
                onFinish()
            },
            onNext: {
                if step == .outro {
                    onFinish()
                } else {
                    controller.advance()
                }
            },
            nextLabel: step == .outro ? "Finish" : "Got It"
        )
    }

    private func stepNumber(for step: TutorialStep) -> Int? {
        switch step {
        case .intro:
            return nil
        case .rotateGesture:
            return 2
        case .scaleGesture:
            return 3
        case .changeBand:
            return 4
        case .addGem:
            return 5
        case .dragGemToSnap:
            return 6
        case .switchToHand:
            return 7
        case .rotateMannequin:
            return 8
        case .outro:
            return nil
        }
    }

    private func ghostKind(for step: TutorialStep) -> GhostGestureKind? {

        switch step {

        case .rotateGesture:
            return .rotate

        case .scaleGesture:
            return .pinch

        case .dragGemToSnap:
            return .drag(
                from: CGPoint(x: -70, y: 0),
                to: CGPoint(x: 20, y: 0)
            )

        default:
            return nil
        }
    }

    private func info(for step: TutorialStep) -> (title: String, text: String) {
        switch step {

        case .intro:
            return (
                "Your Sample File Is Ready!",
                "This is your design file. You can rename it anytime using the pencil icon above."
            )

        case .rotateGesture:
            return (
                "Rotate",
                "Drag with one finger on the screen to rotate the band, or use the gizmo in the bottom-left corner to rotate along a specific axis."
            )

        case .scaleGesture:
            return (
                "Scale",
                "Pinch with two fingers to make the band larger or smaller."
            )

        case .changeBand:
            return (
                "Change Band",
                "Tap the style, thickness, or material options in this panel to change the band's appearance."
            )

        case .addGem:
            return (
                "Add Gem",
                "Choose a gem style and material, then tap \"Add Gem\" to add it to your design."
            )

        case .dragGemToSnap:
            return (
                "Place Gem",
                "Drag the gem with one finger onto a snap point on the band to place it in the correct position."
            )

        case .switchToHand:
            return (
                "View on Hand",
                "Tap the hand button to see your design placed on the mannequin."
            )

        case .rotateMannequin:
            return (
                "Rotate Mannequin",
                "Just like the band, drag with one finger or use the gizmo to rotate the mannequin."
            )

        case .outro:
            return (
                "Ready to Design!",
                "You've learned the basics. This file will stay saved, so you can continue designing anytime."
            )
        }
    }
}
