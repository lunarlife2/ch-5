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
    
    private enum Placement {
        static let aboveBandOffset: CGFloat = 120
        static let sideOfGizmoGap: CGFloat = 200
        static let cardHalfWidth: CGFloat = 200
        static let sideOfHandButton: CGFloat = 200
        static let bottomOfPanelOffset: CGFloat = 100
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let step = controller.currentStep {
                let frame = step.anchor.flatMap {
                    tutorialViewModel.frame(for: $0)
                }
                let bandAreaFrame = tutorialViewModel.frame(for: .bandArea)
                let sidePanelFrame = tutorialViewModel.frame(for: .sidePanel)
                
                ZStack {
                    SpotlightOverlay(
                        targetFrame: frame,
                        cardPositionOverride: { size in
                            cardPlacement(
                                for: step,
                                anchorFrame: frame,
                                bandAreaFrame: bandAreaFrame,
                                sidePanelFrame: sidePanelFrame,
                                in: size
                            )
                        }
                    ) {
                        card(for: step)
                    }
                    .allowsHitTesting(true)
                    
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
                        .allowsHitTesting(false)
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
        .allowsHitTesting(controller.currentStep != nil)
        .ignoresSafeArea()
    }
    
    private func cardPlacement(
        for step: TutorialStep,
        anchorFrame: CGRect?,
        bandAreaFrame: CGRect?,
        sidePanelFrame: CGRect?,
        in size: CGSize
    ) -> CGPoint {
        switch step {
            
        case .rotateBand, .scaleGesture:
            // Above the band viewport
            if let bandAreaFrame {
                let x = min(max(bandAreaFrame.midX, Placement.cardHalfWidth),
                            size.width - Placement.cardHalfWidth)
                let y = max(bandAreaFrame.minY + Placement.aboveBandOffset, 100)
                return CGPoint(x: x, y: y)
            }
            return CGPoint(x: size.width / 2, y: size.height)
            
        case .dragGemToSnap:
            // Above the band viewport
            if let bandAreaFrame {
                let x = min(max(bandAreaFrame.midX, Placement.cardHalfWidth),
                            size.width - Placement.cardHalfWidth)
                let y = bandAreaFrame.maxY - Placement.bottomOfPanelOffset
                return CGPoint(x: x, y: y)
            }
            return CGPoint(x: size.width / 2, y: size.height)
            
        case .rotateGizmo:
            if let anchorFrame {
                let x = min(anchorFrame.maxX + Placement.sideOfGizmoGap,
                            size.width - Placement.cardHalfWidth)
                return CGPoint(x: x, y: anchorFrame.midY)
            }
            return CGPoint(x: size.width / 2, y: size.height / 2)

        case .switchToHand:
            if let anchorFrame {
                let x = min(anchorFrame.maxX + Placement.sideOfHandButton,
                            size.width - Placement.cardHalfWidth)
                return CGPoint(x: x, y: anchorFrame.midY)
            }
            return CGPoint(x: size.width / 2, y: size.height / 2)
            
        case .addGem, .changeBand, .changeHandColor:
            // Bottom of SelectBandGemView / SelectSkinSizeView (side panel)
            if let sidePanelFrame {
                let x = min(max(sidePanelFrame.midX, sidePanelFrame.minX + Placement.cardHalfWidth),
                            sidePanelFrame.maxX - Placement.cardHalfWidth)
                let y = sidePanelFrame.maxY - Placement.bottomOfPanelOffset
                return CGPoint(x: x, y: y)
            }
            return CGPoint(x: size.width, y: size.height)
            
        default:
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
    
    @ViewBuilder
    private func card(for step: TutorialStep) -> some View {
        
        let content = info(for: step)
        
        CoachMarkCard(
            title: content.title,
            subtitle: content.text,
            stepInfo: stepNumber(for: step).map { ($0, 8) },
            onSkip: {
                controller.finish()
                onFinish()
            },
            onNext: step.requiresUserAction ? nil : {
                if step == .outro {
                    controller.finish()
                    onFinish()
                } else {
                    controller.advance()
                }
            },
            nextLabel: step == .outro ? "Finish" : "Got It",
            pendingActionHint: step.requiresUserAction ? "Make the gesture first" : nil
        )
        .padding(.vertical, 8)
    }
    
    private func stepNumber(for step: TutorialStep) -> Int? {
        switch step {
        case .intro:
            return nil
        case .rotateBand:
            return 1
        case .rotateGizmo:
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
        case .changeHandColor:
            return 8
        case .outro:
            return nil
        }
    }
    
    private func ghostKind(for step: TutorialStep) -> GhostGestureKind? {
        
        switch step {
            
        case .rotateBand:
            return .rotate
            
        case .rotateGizmo:
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
            
        case .rotateBand:
            return (
                "Rotate",
                "Drag with one finger on the screen to rotate the band"
            )
            
        case .rotateGizmo:
            return (
                "Rotate",
                "Or use the gizmo in the bottom-left corner to rotate along a specific axis."
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
            
        case .changeHandColor:
            return (
                "Change Skin Color",
                "Choose a skin color and apply it to the hand mannequin"
            )
            
        case .outro:
            return (
                "Ready to Design!",
                "You've learned the basics. This file will stay saved, so you can continue designing anytime."
            )
        }
    }
}
