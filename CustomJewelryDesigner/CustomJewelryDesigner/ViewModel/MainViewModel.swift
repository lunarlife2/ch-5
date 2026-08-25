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
class ViewModel {

    private(set) var sceneState: SceneState = .home

    let tutorialController = TutorialController()

    func moveScreenState(to new: SceneState) {
        self.sceneState = new
    }
}

enum SceneState {

    case home
    case edit(DesignFile)
    case detail(DesignFile)
    case folder(DesignFolder)
    case handSize

    @ViewBuilder
    func viewAssociated(using vm: ViewModel) -> some View {

        switch self {

        case .home:
            HomeView()

        case .edit(let designFile):
            EditView(
                designFile: designFile,
                tutorialController: vm.tutorialController
            )

        case .folder(let folder):
            FolderView(folder: folder)

        case .handSize:
            HandSizeView()

        case .detail(let designFile):
            DetailView(designFile: designFile)
        }
    }
}
