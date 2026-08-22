//
//  EditView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI
import SwiftData
import RealityKit
 
struct EditView: View {
 
    @Environment(ViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
 
    let designFile: DesignFile
 
    @State private var editViewModel: EditViewModel
    @State private var bandGemViewModel = BandGemViewModel()
    @State private var selectedPanelType = 0
    @State private var showUnsavedChangesAlert = false
 
    init(designFile: DesignFile) {
        self.designFile = designFile
        _editViewModel = State(initialValue: EditViewModel(designFile: designFile))
    }
 
    @State private var panelWidth: CGFloat = Layout.expandedWidth
    @State private var selectedGizmoAxis: ViewAxis?
    @State private var bottomControlsHeight: CGFloat = 0
 
    private enum Layout {
        static let expandedWidth: CGFloat = 400
        static let collapsedWidth: CGFloat = 0
        static let trashLeadingPadding: CGFloat = 10
        static let bottomPadding: CGFloat = 20
        static let liveDragGemSize: CGFloat = 36
        static let saveButtonWidth: CGFloat = 62
        static let bottomLeftPadding: CGFloat = 20
    }
 
    var body: some View {
        VStack(spacing: 0) {
            topBar
 
            Divider()
 
            ZStack(alignment: .bottomTrailing) {
                editorAndPanel
                bottomControls
            }
        }
        .overlay {
            liveDragOverlay
        }
        .environment(editViewModel)
        .alert("Delete this gem?", isPresented: isPendingDeleteAlertPresented) {
            Button("Delete", role: .destructive) {
                editViewModel.confirmPendingDelete()
            }
            Button("Cancel", role: .cancel) {
                editViewModel.cancelPendingDelete()
            }
        } message: {
            Text("The gem you drag to the trash will be deleted.")
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
 
    private var topBar: some View {
        HStack {
            topLeftControls
            Spacer()
            topRightControls
        }
        .padding(.vertical, 12)
    }
 
    private var topLeftControls: some View {
        HStack {
            ButtonOri {
                handleBackTap()
            } label: {
                Image(systemName: "chevron.left")
            }
            .padding(.trailing, 20)
 
            //title
            Text(editViewModel.designFile.name)
                .font(.system(size: 20, weight: .semibold))
 
            //edit
            Image(systemName: "pencil")
        }
        .padding(.leading, 30)
    }
 
    private var topRightControls: some View {
        HStack {
            ButtonOri {
                withAnimation(.smooth) {
                    panelWidth = panelWidth > 0 ? Layout.collapsedWidth : Layout.expandedWidth
                }
            } label: {
                Image(systemName: "sidebar.right")
            }
 
            saveButton
        }
        .padding(.trailing, 20)
    }
  
    private var editorAndPanel: some View {
        HStack(spacing: 0) {
 
            JewelryEditorView(
                viewModel: editViewModel,
                bottomInset: bottomControlsHeight
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
 
            sidePanel
        }
    }
 
    private var sidePanel: some View {
        HStack(spacing: 0) {
            Divider()
 
            Group {
                switch editViewModel.mode {
                case .band:
                    SelectBandGemView(
                        selectedType: $selectedPanelType,
                        bandGemViewModel: bandGemViewModel,
                        viewModel: editViewModel
                    )
                    
                case .handMannequin:
                    MannequinView(viewModel: editViewModel)
                }
            }
            .padding(.trailing, 50)
            .frame(width: Layout.expandedWidth, alignment: .topLeading)
        }
        .frame(width: Layout.expandedWidth, alignment: .leading)
        .offset(x: Layout.expandedWidth - panelWidth)
        .frame(width: panelWidth, alignment: .leading)
        .clipped()
        .task {
            await editViewModel.fetchAllData()
            if let design = designFile.design {
                bandGemViewModel.loadRingSize(
                    id: design.ringSizeID,
                    system: design.ringSizeSystem
                )
            }
 
            print("Band:", editViewModel.bands.count)
            print("Gem:", editViewModel.gems.count)
            print("Style:", editViewModel.bandStyles.count)
        }
    }
 
    private func handleBackTap() {
        if editViewModel.hasUnsavedChanges {
            showUnsavedChangesAlert = true
        } else {
            vm.moveScreenState(to: .home)
        }
    }
 
    private var bottomControls: some View {
        VStack(spacing: 10) {
            handButton
            gizmo
        }
        .padding(.leading, Layout.bottomLeftPadding)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { editViewModel.setBottomControlsFrame(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, f in editViewModel.setBottomControlsFrame(f) }
            }
        )
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
    }
 
    private var gizmo: some View {
        Group {
            switch editViewModel.mode {
            case .band:
                OrientationGizmoView(
                    orientation: editViewModel.scene.bandOrientation,
                    selectedAxis: $selectedGizmoAxis,
                    onAxisSelected: { axis, targetOrientation in
                        editViewModel.scene.snapBand(to: targetOrientation)
                    },
                    onRotate: { deltaX, deltaY in
                        editViewModel.scene.rotateBand(deltaX: Float(deltaX), deltaY: Float(deltaY))
                    },
                    onRotateBegin: { editViewModel.scene.beginRotateBand() },
                    onRotateEnd: { editViewModel.scene.endRotateBand() }
                )

            case .handMannequin:
                OrientationGizmoView(
                    orientation: editViewModel.scene.mannequinOrientation,
                    selectedAxis: $selectedGizmoAxis,
                    onAxisSelected: { axis, targetOrientation in
                        editViewModel.scene.snapMannequin(to: targetOrientation)
                    },
                    onRotate: { deltaX, deltaY in
                        editViewModel.scene.rotateMannequin(deltaX: Float(deltaX), deltaY: Float(deltaY))
                    },
                    onRotateBegin: { editViewModel.scene.beginRotateMannequin() },
                    onRotateEnd: { editViewModel.scene.endRotateMannequin() }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
 
 
    private func rotateSelected(_ entity: Entity, axis: ViewAxis, step: Float = .pi / 2) {
        let axisVec: SIMD3<Float>
        switch axis {
        case .x:
            axisVec = SIMD3<Float>(1, 0, 0)
 
        case .negativeX:
            axisVec = SIMD3<Float>(-1, 0, 0)
 
        case .y:
            axisVec = SIMD3<Float>(0, 1, 0)
 
        case .negativeY:
            axisVec = SIMD3<Float>(0, -1, 0)
 
        case .z:
            axisVec = SIMD3<Float>(0, 0, 1)
 
        case .negativeZ:
            axisVec = SIMD3<Float>(0, 0, -1)
        }
 
        entity.orientation = simd_quatf(angle: step, axis: axisVec) * entity.orientation
 
        editViewModel.markDirty()
    }
    
    private var handButton: some View {
        GlassButton {
            withAnimation {
                editViewModel.mode =
                editViewModel.mode == .band
                ? .handMannequin
                : .band
            }
        } label: {
            Image(
                systemName:
                    editViewModel.mode == .band
                ? "hand.raised"
                : "circle"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
 
    private var trashButton: some View {
        GlassButton {
            editViewModel.delete()
        } label: {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete design")
        .padding(.leading, Layout.trashLeadingPadding)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        editViewModel.setTrashFrame(proxy.frame(in: .global))
                    }
                    .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                        editViewModel.setTrashFrame(newFrame)
                    }
            }
        )
    }
 
    private var saveButton: some View {
        Button {
            guard editViewModel.hasUnsavedChanges else { return }
            editViewModel.save(
                ringSizeID: bandGemViewModel.selectedRingSizeID,
                ringSizeSystem: bandGemViewModel.selectedRingSizeSystem,
                finger: bandGemViewModel.selectedFinger,
                hand: bandGemViewModel.selectedHand
            )
            vm.moveScreenState(to: .home)
        } label: {
            Text("Save")
                .frame(maxWidth: Layout.saveButtonWidth)
        }
        .buttonStyle(.glassProminent)
        .disabled(!editViewModel.hasUnsavedChanges)
        .frame(minWidth: 100)
    }
 
    private var liveDragOverlay: some View {
        GeometryReader { proxy in
            if let globalPoint = editViewModel.liveDragGlobalPoint {
                let localPoint = CGPoint(
                    x: globalPoint.x - proxy.frame(in: .global).minX,
                    y: globalPoint.y - proxy.frame(in: .global).minY
                )
                Image("gemstone-blue")
                    .resizable()
                    .frame(width: Layout.liveDragGemSize, height: Layout.liveDragGemSize)
                    .position(localPoint)
                    .allowsHitTesting(false)
            }
        }
    }
 
    private var isPendingDeleteAlertPresented: Binding<Bool> {
        Binding(
            get: { editViewModel.pendingDeleteGemName != nil },
            set: { isPresented in
                if !isPresented {
                    editViewModel.cancelPendingDelete()
                }
            }
        )
    }
}
