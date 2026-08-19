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

    init(designFile: DesignFile) {
        self.designFile = designFile
        _editViewModel = State(initialValue: EditViewModel(designFile: designFile))
    }
    

    @State private var panelWidth: CGFloat = Layout.expandedWidth
    @State private var dragStartWidth: CGFloat = Layout.expandedWidth
    @State private var selectedGizmoAxis: ViewAxis?
    @State private var bottomControlsHeight: CGFloat = 0

    private enum Layout {
        static let expandedWidth: CGFloat = 408
        static let collapsedWidth: CGFloat = 20
        static let panelHeight: CGFloat = 558
        static let collapseDistanceThreshold: CGFloat = 90
        static let screenMargin: CGFloat = 20
        static let saveMinimumWidth: CGFloat = 140
        static let trashLeadingPadding: CGFloat = 50
        static let bottomPadding: CGFloat = 20
        static let liveDragGemSize: CGFloat = 36
        static let resizeHandlePadding: CGFloat = 10
    }

    private var expandProgress: CGFloat {
        let range = Layout.expandedWidth - Layout.collapsedWidth
        guard range > 0 else { return 0 }
        return (panelWidth - Layout.collapsedWidth) / range
    }

    private var saveWidth: CGFloat {
        max(panelWidth, Layout.saveMinimumWidth)
    }

    private var panelRightPadding: CGFloat {
        Layout.screenMargin * expandProgress
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            editorAndPanel
            bottomControls
        }
        .overlay {
            liveDragOverlay
        }
        .environment(editViewModel)
        .alert(
            "Delete this gem?",
            isPresented: isPendingDeleteAlertPresented
        ) {
            Button("Delete", role: .destructive) {
                editViewModel.confirmPendingDelete()
            }
            Button("Cancel", role: .cancel) {
                editViewModel.cancelPendingDelete()
            }
        } message: {
            Text("The gem you drag to the trash will be deleted.")
        }
    }

    private var editorAndPanel: some View {
        HStack(spacing: 0) {

            JewelryEditorView(
                viewModel: editViewModel,
                bottomInset: bottomControlsHeight
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

            SelectBandGemView(
                bandGemViewModel: bandGemViewModel,
                viewModel: editViewModel,
                panelWidth: panelWidth,
                expandedWidth: Layout.expandedWidth,
                collapsedWidth: Layout.collapsedWidth
            )
            .frame(
                width: panelWidth,
                height: Layout.panelHeight,
                alignment: .leading
            )
            .padding(.trailing, panelRightPadding)
            .task {
                await editViewModel.fetchAllData()

                print("Band:", editViewModel.bands.count
                )

                print(
                    "Gem:",
                    editViewModel.gems.count
                )

                print(
                    "Style:",
                    editViewModel.bandStyles.count
                )
            }
            .overlay(alignment: .bottomLeading) {

                ResizeHandle()
                    .padding(
                        .leading,
                        Layout.resizeHandlePadding
                    )
                    .padding(
                        .bottom,
                        Layout.resizeHandlePadding
                    )
                    .gesture(resizeGesture)
            }
        }
    }
    private var bottomControls: some View {
        HStack {
            gizmo

            Spacer()

            saveButton
        }
        .reportHeight(
            BottomControlsHeightKey.self
        )
        .onPreferenceChange(
            BottomControlsHeightKey.self
        ) { height in
            bottomControlsHeight = height
        }
    }
    
    private var gizmo: some View {
        OrientationGizmoView(
            orientation: editViewModel.scene.bandOrientation,
            selectedAxis: $selectedGizmoAxis,

            onAxisSelected: { axis, targetOrientation in
                editViewModel.scene.snapBand(to: targetOrientation)
            },
            onRotate: { deltaX, deltaY in
                editViewModel.scene.rotateBand(
                    deltaX: Float(deltaX),
                    deltaY: Float(deltaY)
                )
            },

            onRotateBegin: {
                editViewModel.scene.beginRotateBand()
            },

            onRotateEnd: {
                editViewModel.scene.endRotateBand()
            }
        )
        .padding(.leading, Layout.trashLeadingPadding)
    }
    
    
    private func rotateSelected(
        _ entity: Entity,
        axis: ViewAxis,
        step: Float = .pi / 2
    ) {

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

        entity.orientation =
            simd_quatf(
                angle: step,
                axis: axisVec
            ) * entity.orientation

        editViewModel.markDirty()
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
                ringSizeSystem: bandGemViewModel.selectedRingSizeSystem
            )
            vm.moveScreenState(to: .home)
        } label: {
            Text("Save")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .disabled(!editViewModel.hasUnsavedChanges)
        .frame(width: saveWidth)
        .padding(.trailing, Layout.screenMargin)
        .padding(.bottom, Layout.bottomPadding)
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

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let newWidth = dragStartWidth - value.translation.width
                panelWidth = min(
                    Layout.expandedWidth,
                    max(Layout.collapsedWidth, newWidth)
                )
            }
            .onEnded { value in
                withAnimation(.smooth) {
                    panelWidth = value.translation.width > Layout.collapseDistanceThreshold
                        ? Layout.collapsedWidth
                        : Layout.expandedWidth
                    dragStartWidth = panelWidth
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
