//
//  TutorialController.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//

import SwiftUI

//enum TutorialStep: Int, CaseIterable {
//    case intro, rotateGesture, gizmo, changeBand, addGem, switchToMannequin, outro
//}

enum TutorialStep: Int, CaseIterable {
    case intro
    case rotateGesture
    case scaleGesture
    case changeBand
    case addGem
    case dragGemToSnap
    case switchToHand
    case rotateMannequin
    case outro
    
    var anchor: TutorialID? {
        switch self {
        case .rotateGesture, .rotateMannequin: return .gizmo
        case .changeBand, .addGem: return .sidePanel
        case .switchToHand: return .handButton
        default: return nil
        }
    }
}

@Observable
@MainActor
final class TutorialController {
    private(set) var currentStep: TutorialStep?
    
    func start() { currentStep = .intro }
    
    func advance() {
        guard let current = currentStep,
              let idx = TutorialStep.allCases.firstIndex(of: current),
              idx + 1 < TutorialStep.allCases.count else {
            currentStep = nil
            return
        }
        currentStep = TutorialStep.allCases[idx + 1]
    }
    
    func advance(ifCurrentlyAt step: TutorialStep) {
        if currentStep == step { advance() }
    }
    
    func reportUserAction(_ action: TutorialUserAction) {
        guard let step = currentStep, step.matches(action) else { return }
        advance()
    }
    
}

enum TutorialUserAction {
    case rotated, scaled, draggedGem, addedGem, switchedToHand, rotatedMannequin
}

extension TutorialStep {
    func matches(_ action: TutorialUserAction) -> Bool {
        switch (self, action) {
        case (.rotateGesture, .rotated),
             (.scaleGesture, .scaled),
             (.dragGemToSnap, .draggedGem),
             (.addGem, .addedGem),
             (.switchToHand, .switchedToHand),
             (.rotateMannequin, .rotatedMannequin):
            return true
        default:
            return false
        }
    }
}
