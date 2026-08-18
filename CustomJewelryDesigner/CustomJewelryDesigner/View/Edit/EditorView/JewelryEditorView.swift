//
//  JewelryEditorView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 11/08/26.
//

import SwiftUI
import RealityKit
import SwiftData

struct JewelryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    
    let viewModel: EditViewModel
    
    @State private var isTargeted = false
    @State private var touchTracker = TouchCountViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(ViewModel.self) private var vm
    
    
    @State private var showUnsavedChangesAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RealityView { content in
                    content.add(viewModel.scene.rootEntity)
                    viewModel.setRealityContent(content)
                }
                .gesture(TouchCounterView(tracker: touchTracker))
                .simultaneousGesture(DragAndDropGesture(touchTracker: touchTracker, editViewModel: viewModel, scene: viewModel.scene).dragGesture)
                .gesture(
                    TwoFingerTransformGesture(touchTracker: touchTracker, entityProvider: { location in viewModel.scene.entityAtScreenLocation(location)}, editViewModel: viewModel, sceneController: viewModel.scene))
                
                VStack(alignment: .leading) {
                    HStack {
                        //back button
                        GlassButton {
                            handleBackTap()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        
                        Spacer()
                        
                        //switch ring and hand view
                        SwitchView(viewModel: viewModel)
                    }
                    
                    Spacer()
                }
                .padding(.top, geometry.safeAreaInsets.top)
                .padding(.leading, 50)
            }
            .task {
                modelContext.autosaveEnabled = false
                viewModel.setModelContext(modelContext)
                
                await viewModel.fetchAllData()
                await viewModel.loadScene()
            }
            .dropDestination(for: JewelryDropPayload.self) { (items: [JewelryDropPayload], location: CGPoint) -> Bool in
                guard let payload = items.first else { return false }
                let size = geometry.size
                Task {
                    await viewModel.handleDrop(
                        item: payload,
                        screenLocation: location,
                        containerSize: size
                    )
                }
                return true
            }
            .onAppear {
                viewModel.setEditorFrame(
                    geometry.frame(in: .global)
                )
            }
            .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                viewModel.setEditorFrame(newFrame)
            }
        }
        .onDisappear {
            GestureLock.shared.forceRelease()
            TransformSession.shared.forceEndIfStuck()
        }
        .alert(
            "Changes have not been saved.",
            isPresented: $showUnsavedChangesAlert
        ) {
            Button(
                "Exit Without Saving",
                role: .destructive
            ) {
                modelContext.rollback()
                vm.moveScreenState(to: .home)
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "You have unsaved changes. " +
                "This design will remain temporarily saved " +
                "as long as the app is not force-closed."
            )
        }
    }
    
    private func handleBackTap() {
        if viewModel.hasUnsavedChanges {
            showUnsavedChangesAlert = true
        } else {
            vm.moveScreenState(to: .home)
        }
    }
}


//#Preview {
//    JewelryEditorView(
//        viewModel: EditViewModel(designFile: )
//    )
//}
