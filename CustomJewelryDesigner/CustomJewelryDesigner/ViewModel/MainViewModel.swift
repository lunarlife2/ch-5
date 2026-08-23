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
	func moveScreenState(to new: SceneState) {
		self.sceneState = new

	}
}

// Programmatically move scene
enum SceneState {

	case home
	case edit(DesignFile)
	case detail
	case folder(_ :DesignFolder)

	@ViewBuilder func viewAssociated() -> some View {

		switch self {
		case .home:
			HomeView()
		case .edit(let designFile):
            EditView(designFile: designFile)
		case .detail:
			DetailView()
		case .folder(let folder):
			FolderView(folder: folder)
		}

	}
}
