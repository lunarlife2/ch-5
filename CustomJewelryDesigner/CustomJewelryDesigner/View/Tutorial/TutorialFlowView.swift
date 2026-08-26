//
//  TutorialFlowView.swift
//  CustomJewelryDesigner
//

import SwiftUI
import SwiftData

struct TutorialFlowView: View {

    @Environment(\.modelContext) private var modelContext

    var onboarding: OnBoardingService

    /// Dipanggil ketika tutorial selesai.
    /// File tutorial yang sudah dibuat dikirim ke normal editor flow.
    let onFinishTutorial: (DesignFile) -> Void

    private enum Phase {
        case intro
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
                    onCreateFile: { _ in
                        startTutorial()
                    },
                    showsCreateCoachMark: false
                )

                TutorialIntroView {
                    startTutorial()
                }
            }

        case .editing(let file):

            EditView(
                designFile: file,
                tutorialViewModel: tutorialViewModel,
                tutorialController: tutorial
            )
            .overlay {

                TutorialOverlayView(
                    controller: tutorial,
                    tutorialViewModel: tutorialViewModel
                ) {

                    print("🎓 TUTORIAL FINISHED")

                    tutorial.finish()

                    // Tandai onboarding selesai
                    onboarding.hasCompletedTutorial = true

                    // PENTING:
                    // Jangan ubah phase ke normal editor di sini.
                    // Jangan reuse EditViewModel.
                    // Lempar file ke normal app flow.
                    print("➡️ Leaving TutorialFlowView")

                    onFinishTutorial(file)
                }
            }
        }
    }

    private func startTutorial() {

        let store = DesignFileStore(
            modelContext: modelContext
        )

        let file = store.createDesignFile(
            name: "Engagement Ring"
        )

        print("🎬 Starting tutorial for:", file.name)

        tutorial.start()

        phase = .editing(file)
    }
}
