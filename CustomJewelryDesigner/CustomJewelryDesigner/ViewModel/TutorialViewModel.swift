//
//  TutorialViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//

import SwiftUI

enum TutorialID: Hashable {
    case createButton
    case gizmo
    case handButton
    case sidePanel
}

@Observable
final class TutorialViewModel {
    private(set) var frames: [TutorialID: CGRect] = [:]

    func setFrame(_ frame: CGRect, for id: TutorialID) {
        frames[id] = frame
    }

    func frame(for id: TutorialID?) -> CGRect? {
        guard let id else { return nil }
        return frames[id]
    }
}

extension View {
    func tutorialAnchor(_ id: TutorialID, viewModel: TutorialViewModel) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { viewModel.setFrame(proxy.frame(in: .global), for: id) }
                    .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                        viewModel.setFrame(newFrame, for: id)
                    }
            }
        )
    }
}
