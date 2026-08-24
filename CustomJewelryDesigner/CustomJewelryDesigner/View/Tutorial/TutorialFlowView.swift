//
//  TutorialFlowView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//


import SwiftUI
import SwiftData

struct TutorialFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ViewModel.self) private var vm

    var onboarding: OnBoardingService

    private enum Phase {
        case intro
        case creatingFile
        case editing(DesignFile)
    }

    @State private var phase: Phase = .intro
    @State private var tutorialViewModel = TutorialViewModel()
    @State private var tutorial = TutorialController()

    var body: some View {
        switch phase {
        case .intro:
            ZStack {
                TutorialView(
                    onboarding: onboarding,
                    tutorialViewModel: tutorialViewModel,
                    onCreateFile: { name in
                        let store = DesignFileStore(modelContext: modelContext)
                        let file = store.createDesignFile(name: name)
                        tutorial.start()
                        phase = .editing(file)
                    },
                    showsCreateCoachMark: false
                )
                TutorialIntroView {
                    phase = .creatingFile
                }
            }

        case .creatingFile:
            TutorialView(
                onboarding: onboarding,
                tutorialViewModel: tutorialViewModel,
                onCreateFile: { name in
                    let store = DesignFileStore(modelContext: modelContext)
                    let file = store.createDesignFile(name: name)
                    tutorial.start()
                    phase = .editing(file)
                },
                showsCreateCoachMark: true
            )

        case .editing(let file):
            EditView(designFile: file, tutorialController: tutorial)
                .overlay {
                    TutorialOverlayView(
                        controller: tutorial,
                        tutorialViewModel: tutorialViewModel
                    ) {
                        vm.moveScreenState(to: .edit(file))
                        onboarding.hasCompletedTutorial = true
                    }
                }
        }
    }
}
