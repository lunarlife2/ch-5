//
//  MainViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 14/08/26.
//

import Combine
import SwiftUI

@Observable
@MainActor
final class ViewModel {

    private(set) var sceneState: SceneState = .home

    let tutorialController = TutorialController()

    let bandGemViewModel = BandGemViewModel()

    // MARK: - Active editor

    // Ini yang mempertahankan EditViewModel
    // ketika TutorialFlowView dibuang.
    private(set) var activeEditViewModel: EditViewModel?

    // MARK: - Navigation

    func moveScreenState(to new: SceneState) {
        sceneState = new
    }

    func openEditor(
        _ designFile: DesignFile,
        editViewModel: EditViewModel? = nil
    ) {
        activeEditViewModel = editViewModel
        sceneState = .edit(designFile)
    }

    func openNormalEditor(_ designFile: DesignFile) {
        activeEditViewModel = nil
        sceneState = .edit(designFile)
    }

    func closeEditor() {
        activeEditViewModel = nil
        sceneState = .home
    }
}

enum SceneState {
    case home

    case edit(DesignFile)

    case detail(DesignFile)

    case folder(DesignFolder)

    case handSize(
        initialSelectedFinger: HandFinger?
    )

    @ViewBuilder
    func viewAssociated(using vm: ViewModel) -> some View {

        switch self {

        case .home:
            HomeView()

        case .edit(let designFile):

            EditView(
                designFile: designFile,
                tutorialController: vm.tutorialController,
                editViewModel: vm.activeEditViewModel
            )

        case .folder(let folder):
            FolderView(folder: folder)

        case .handSize(let initialSelectedFinger):

            HandSizeView(
                bandGemViewModel: vm.bandGemViewModel,
                initialSelectedFinger: initialSelectedFinger
            )

        case .detail(let designFile):
            DetailView(designFile: designFile)
        }
    }
}
