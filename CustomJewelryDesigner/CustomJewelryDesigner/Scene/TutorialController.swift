//
//  TutorialController.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//

import SwiftUI

enum TutorialStep: Int, CaseIterable {
    case intro
    case rotateBand
    case rotateGizmo
    case scaleGesture
    case changeBand
    case addGem
    case dragGemToSnap
    case switchToHand
    case changeHandColor
    case outro

    var anchor: TutorialID? {
        switch self {
        case .rotateBand: return .bandArea
        case .rotateGizmo: return .gizmo
        case .switchToHand: return .handButton
        case .changeBand, .addGem, .changeHandColor: return .sidePanel
        default: return nil
        }
    }

    var requiresUserAction: Bool {
        switch self {
        case .rotateBand, .rotateGizmo, .scaleGesture, .changeBand,
             .addGem, .dragGemToSnap, .switchToHand, .changeHandColor:
            return true
        case .intro, .outro:
            return false
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

    // tambahin ini
    func finish() {
        currentStep = nil
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
    case rotatedBand, rotatedGizmo, scaled, changedBand, draggedGem, addedGem, switchedToHand, changedHandColor
}

extension TutorialStep {
    func matches(_ action: TutorialUserAction) -> Bool {
        switch (self, action) {
        case (.rotateBand, .rotatedBand),
            (.rotateGizmo, .rotatedGizmo),
            (.scaleGesture, .scaled),
            (.changeBand, .changedBand),
            (.dragGemToSnap, .draggedGem),
            (.addGem, .addedGem),
            (.switchToHand, .switchedToHand),
            (.changeHandColor, .changedHandColor):
            return true
        default:
            return false
        }
    }
}
