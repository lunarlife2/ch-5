//
//  MainViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 14/08/26.
//

import Combine
import SwiftUI

@MainActor
@Observable class ViewModel {

	private(set) var sceneState: SceneState = .home

}

// Screen Manager
extension ViewModel {

	func moveScreenState(to new: SceneState) {
		self.sceneState = new

	}
}

// Programmatically move scene
enum SceneState {

	case home
	case edit
	case detail
	//case storie(_ :StoryModel)

	@ViewBuilder func viewAssociated() -> some View {

		switch self {
		case .home:
			HomeView()
		case .edit:
			EditView()
		case .detail:
			DetailView()
//		case .storie(let storie):
//			StoryView(story: storie)
		}

	}
}
