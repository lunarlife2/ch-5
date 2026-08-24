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
    @Environment(\.dismiss) private var dismiss
    @Environment(ViewModel.self) private var vm
    
    let viewModel: EditViewModel
    let bottomInset: CGFloat
    let tutorial: TutorialController
    
    @State private var isTargeted = false
    @State private var touchTracker = TouchCountViewModel()
    @State private var showUnsavedChangesAlert = false
    @State private var topBarHeight: CGFloat = 0
    @State private var isScaleDragging = false
    @State private var isRotateDragging = false
    
    private var topInset: CGFloat {
        topSafeArea + topBarHeight
    }
    
    private var topSafeArea: CGFloat {
        safeAreaTop
    }
    
    @State private var safeAreaTop: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            
            ZStack {
                realityView(
                    geometry: geometry
                )
                
                gemActionIcons
                
                if viewModel.isLoadingAsset {
                    loadingOverlay
                }
                
            }
            .onAppear {
                safeAreaTop = geometry.safeAreaInsets.top
                
                updateEditorFrame(
                    geometry: geometry
                )
            }
            .onChange(of: geometry.frame(in: .global)) { _, _ in
                updateEditorFrame(
                    geometry: geometry
                )
            }
            .onChange(of: geometry.size) { _, _ in
                updateEditorFrame(
                    geometry: geometry
                )
            }
            .onChange(of: topBarHeight) { _, _ in
                updateEditorFrame(
                    geometry: geometry
                )
            }
            .onChange(of: bottomInset) { _, _ in
                updateEditorFrame(
                    geometry: geometry
                )
            }
            .task {
                modelContext.autosaveEnabled = false
                
                viewModel.setModelContext(modelContext)
                await viewModel.refreshData()
                await viewModel.fetchAllData()
                await viewModel.loadScene()
            }
            .dropDestination(for: JewelryDropPayload.self) { items, location in
                guard let payload = items.first else {
                    return false
                }
                
                let realityLocation = CGPoint(
                    x: location.x,
                    y: location.y - topInset
                )
                
                let realitySize = insetSize(
                    geometry.size
                )
                
                Task {
                    let gemBefore = viewModel.gems.count
                    await viewModel.handleDrop(
                        item: payload,
                        screenLocation: realityLocation,
                        containerSize: realitySize
                    )
                }
                
                return true
            }
        }
        .onDisappear {
            GestureLock.shared.forceRelease()
            TransformSession.shared.forceEndIfStuck()
        }
    }
    
    @ViewBuilder
    private func realityView(geometry: GeometryProxy) -> some View {
        RealityView { content in
            content.add(viewModel.scene.rootEntity)
            content.subscribe(to: SceneEvents.Update.self) { _ in
                viewModel.updateSelectedGemIconPositions()
            }
            viewModel.setRealityContent(content)
        }
        .clipped()
        .gesture(
            SpatialTapGesture()
                .onEnded { value in
                    let globalPoint = CGPoint(
                        x: geometry.frame(in: .global).minX + value.location.x,
                        y: geometry.frame(in: .global).minY + value.location.y
                    )
                    let clampedGlobal = viewModel.clampToSafeArea(globalPoint)
                    let realityLocation = localPoint(fromGlobal: clampedGlobal, geometry: geometry)
                    
                    viewModel.scene.selectEntity(at: realityLocation)
                    viewModel.syncSelectionFromGizmo()
                    viewModel.updateSelectedGemIconPositions()
                }
        )
        .gesture(TouchCounterView(tracker: touchTracker))
        .simultaneousGesture(
            DragAndDropGesture(
                touchTracker: touchTracker,
                editViewModel: viewModel,
                scene: viewModel.scene,
                tutorial: tutorial
            ).dragGesture
        )
        .simultaneousGesture(
            RingRotationGesture(
                touchTracker: touchTracker,
                editViewModel: viewModel,
                scene: viewModel.scene,
            ).rotateGesture
        )
        .gesture(
            TwoFingerTransformGesture(
                touchTracker: touchTracker,
                entityProvider: { location in
                    let globalPoint = CGPoint(
                        x: geometry.frame(in: .global).minX + location.x,
                        y: geometry.frame(in: .global).minY + location.y - 0
                    )
                    let localLoc = localPoint(fromGlobal: globalPoint, geometry: geometry)
                    return viewModel.scene.entityAtScreenLocation(localLoc)
                },
                editViewModel: viewModel,
                sceneController: viewModel.scene
            )
        )
    }
    
    private func localPoint(fromGlobal point: CGPoint, geometry: GeometryProxy) -> CGPoint {
        CGPoint(
            x: point.x - geometry.frame(in: .global).minX,
            y: point.y - geometry.frame(in: .global).minY
        )
    }
    
    private func updateEditorFrame(geometry: GeometryProxy) {
        viewModel.setEditorFrame(geometry.frame(in: .global))
    }
    
    
    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.15)
            ProgressView()
                .controlSize(.large)
                .padding(24)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(
                        cornerRadius: 16
                    )
                )
        }
        .allowsHitTesting(true)
    }
    
    private func insetFrame(_ frame: CGRect, topInset: CGFloat) -> CGRect {
        let bottom = max(0, min(bottomInset, frame.height - topInset))
        let top = max(0, min(topInset, frame.height))
        let height = max(0, frame.height - top - bottom)
        return CGRect(x: frame.minX, y: frame.minY + top, width: frame.width, height: height)
    }
    
    private func insetSize(_ size: CGSize) -> CGSize {
        let top = min(max(0, topInset), size.height)
        let bottom = min(max(0, bottomInset), max(0, size.height - top))
        return CGSize(width: size.width, height: max(0, size.height - top - bottom))
    }
    
    private func handleBackTap() {
        if viewModel.hasUnsavedChanges {
            showUnsavedChangesAlert = true
        } else {
            vm.moveScreenState(to: .home)
        }
    }
    
    private var gemActionIcons: some View {
        Group {
            if viewModel.isGemSelected {
                if let trashPos = viewModel.selectedGemTrashPosition {
                    GlassButton {
                        viewModel.requestDeleteSelectedGem()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .position(trashPos)
                }
                
                if let scalePos = viewModel.selectedGemScalePosition {
                    scaleHandle.position(scalePos)
                }
                
                if let rotatePos = viewModel.selectedGemRotatePosition {
                    rotateHandle.position(rotatePos)
                }
            }
        }
    }
    
    private var scaleHandle: some View {
        GlassScaleButton(
            onChanged: { value in
                if !isScaleDragging {
                    isScaleDragging = true
                    viewModel.beginScaleSelectedGem()
                }
                viewModel.updateScaleSelectedGem(translationHeight: value.translation.height)
            },
            onEnded: { _ in
                viewModel.endScaleSelectedGem()
                isScaleDragging = false
            }
        ) {
            Image(systemName: "arrow.up.and.down")
        }
    }
    
    private var rotateHandle: some View {
        GlassRotateButton(
            onBegin: {
                isRotateDragging = true
                viewModel.beginRotateSelectedGem()
            },
            onChanged: { deltaAngle in
                viewModel.updateRotateSelectedGem(deltaAngleRadians: deltaAngle)
            },
            onEnded: {
                viewModel.endRotateSelectedGem()
                isRotateDragging = false
            }
        ) {
            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
        }
    }
    
    @ViewBuilder
    private func topControls(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            HStack {
                GlassButton {
                    handleBackTap()
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                SwitchView(
                    viewModel: viewModel
                )
            }
            .reportHeight(TopBarHeightKey.self)
            
            Spacer()
        }
        .padding(.top, geometry.safeAreaInsets.top)
        .padding(.leading, 50)
        .onPreferenceChange(TopBarHeightKey.self) { height in
            topBarHeight = height
        }
    }
    
}
