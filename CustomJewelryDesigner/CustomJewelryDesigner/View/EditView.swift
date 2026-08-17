//
//  EditView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI
import SwiftData

struct EditView: View {

    @Environment(ViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext

    let designFile: DesignFile

    @State private var viewModel: EditViewModel
    @State private var bandGemViewModel = BandGemViewModel()

    init(designFile: DesignFile) {
        self.designFile = designFile
        _viewModel = State(initialValue: EditViewModel(designFile: designFile))
    }

    @State private var panelWidth: CGFloat = Layout.expandedWidth
    @State private var dragStartWidth: CGFloat = Layout.expandedWidth

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
        .overlay { liveDragOverlay }
        .environment(viewModel)
        .alert(
            "Delete this gem?",
            isPresented: isPendingDeleteAlertPresented
        ) {
            Button("Delete", role: .destructive) {
                viewModel.confirmPendingDelete()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelPendingDelete()
            }
        } message: {
            Text("The gem you drag to the trash will be deleted.")
        }
    }

    private var editorAndPanel: some View {
        HStack(spacing: 0) {
            JewelryEditorView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            SelectBandGemView(
                bandGemViewModel: bandGemViewModel,
                panelWidth: panelWidth,
                expandedWidth: Layout.expandedWidth,
                collapsedWidth: Layout.collapsedWidth
            )
            .frame(width: panelWidth, height: Layout.panelHeight, alignment: .leading)
            .padding(.trailing, panelRightPadding)
            .overlay(alignment: .bottomLeading) {
                ResizeHandle()
                    .padding(.leading, Layout.resizeHandlePadding)
                    .padding(.bottom, Layout.resizeHandlePadding)
                    .gesture(resizeGesture)
            }
        }
    }

    private var bottomControls: some View {
        HStack {
            trashButton
            Spacer()
            saveButton
        }
    }

    private var trashButton: some View {
        GlassButton {
            viewModel.delete()
        } label: {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete design")
        .padding(.leading, Layout.trashLeadingPadding)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        viewModel.setTrashFrame(proxy.frame(in: .global))
                    }
                    .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                        viewModel.setTrashFrame(newFrame)
                    }
            }
        )
    }

    private var saveButton: some View {
        Button {
            guard viewModel.hasUnsavedChanges else { return }
            viewModel.save(
                ringSizeID: bandGemViewModel.selectedRingSizeID,
                ringSizeSystem: bandGemViewModel.selectedRingSizeSystem
            )
            vm.moveScreenState(to: .home)
        } label: {
            Text("Save")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .disabled(!viewModel.hasUnsavedChanges)
        .frame(width: saveWidth)
        .padding(.trailing, Layout.screenMargin)
        .padding(.bottom, Layout.bottomPadding)
    }

    private var liveDragOverlay: some View {
        GeometryReader { proxy in
            if let globalPoint = viewModel.liveDragGlobalPoint {
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
            get: { viewModel.pendingDeleteGemName != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.cancelPendingDelete()
                }
            }
        )
    }
}


//#Preview {
//    EditView(designFile: DesignFile(id: 1, name: "Tes", updatedAt: .now, ringPosition: , design: ))
//}
