//
//  TouchCounterView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 13/08/26.
//
import SwiftUI
import UIKit

struct TouchCounterView: UIGestureRecognizerRepresentable {
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }
    
    let tracker: TouchCountViewModel
 
    func makeUIGestureRecognizer(context: Context) -> TouchCountGestureRecognizer {
        let recognizer = TouchCountGestureRecognizer()
        recognizer.tracker = tracker
        recognizer.delegate = context.coordinator
        return recognizer
    }
 
    func updateUIGestureRecognizer(_ recognizer: TouchCountGestureRecognizer, context: Context) {}
 
    func handleUIGestureRecognizerAction(_ recognizer: TouchCountGestureRecognizer, context: Context) {}
 
    func makeCoordinator() -> Coordinator { Coordinator() }
 
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
