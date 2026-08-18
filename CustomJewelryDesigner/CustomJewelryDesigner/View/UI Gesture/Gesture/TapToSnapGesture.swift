//
//  TapToSnapGesture.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 15/08/26.
//

import SwiftUI
import RealityKit

struct TapToSnapGesture: UIGestureRecognizerRepresentable {
    let entityProvider: (CGPoint) -> Entity?
    let onTap: (Entity) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }

    func makeUIGestureRecognizer(context: Context) -> TapRecognizer {
        let recognizer = TapRecognizer()
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: TapRecognizer, context: Context) {}

    func handleUIGestureRecognizerAction(_ recognizer: TapRecognizer, context: Context) {
        guard recognizer.state == .recognized else { return }
        guard let entity = entityProvider(recognizer.tapLocation),
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone
        else { return }
        onTap(entity)
    }
}
