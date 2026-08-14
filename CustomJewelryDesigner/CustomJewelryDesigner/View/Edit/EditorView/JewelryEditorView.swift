//
//  JewelryEditorView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 11/08/26.
//

import SwiftUI
import RealityKit

struct JewelryEditorView: View {
    
    @State private var viewModel = EditViewModel()
    @State private var isTargeted = false
    @State private var touchTracker = TouchCountViewModel()
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    RealityView { content in
                        content.add(viewModel.rootEntity)
                        viewModel.setRealityContent(content)
                    }
                    .gesture(TouchCounterView(tracker: touchTracker))
                    .simultaneousGesture(DragAndDropGesture(touchTracker: touchTracker).dragGesture)
                    .gesture(TwoFingerTransformGesture(touchTracker: touchTracker, entityProvider: { location in
                            viewModel.entityAtScreenLocation(location)
                        }))
                    
                    VStack(alignment: .leading) {
                        HStack {
                            GlassButton {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                            }

                            Spacer()
                            
                            SwitchView(viewModel: viewModel)
                            
                        }
                        
                        Spacer()
                        
                        GlassButton {
                            viewModel.delete()
                        } label: {
                            Image(systemName: "trash")
                        }

                        
                    }
                    .padding(.top, geometry.safeAreaInsets.top)
                    .padding(.leading, 50)
                }
                .task {
                    await viewModel.setup()
                }
                .dropDestination(for: String.self) { items, location in
                    guard let identifier = items.first else {
                        return false
                    }
                    let size = geometry.size
                    Task {
                        await viewModel.handleDrop(
                            identifier: identifier,
                            screenLocation: location,
                            containerSize: size
                        )
                    }
                    return true
                }
                
                .padding(10)
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .onDisappear {
            GestureLock.shared.forceRelease()
            TransformSession.shared.forceEndIfStuck()
        }
    }
}

#Preview {
    JewelryEditorView()
}
