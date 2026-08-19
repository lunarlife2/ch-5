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
    let bottomInset: CGFloat

    @State private var isTargeted = false
    @State private var touchTracker = TouchCountViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(ViewModel.self) private var vm

    @State private var showUnsavedChangesAlert = false

    @State private var topBarHeight: CGFloat = 0

    // MARK: - Computed Insets

    private var topInset: CGFloat {
        topSafeArea + topBarHeight
    }

    private var topSafeArea: CGFloat {
        // GeometryReader supplies the actual safe-area inset.
        // This value gets assigned in body.
        safeAreaTop
    }

    @State private var safeAreaTop: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in

            ZStack {

                realityView(
                    geometry: geometry
                )

                topControls(
                    geometry: geometry
                )
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

                await viewModel.fetchAllData()
                await viewModel.loadScene()
            }
            .dropDestination(
                for: JewelryDropPayload.self
            ) { items, location in

                guard let payload = items.first else {
                    return false
                }

                // Drop location is relative to the full editor view.
                // RealityKit starts after topInset, so convert it.
                let realityLocation = CGPoint(
                    x: location.x,
                    y: location.y - topInset
                )

                let realitySize = insetSize(
                    geometry.size
                )

                Task {
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

    // MARK: - RealityView

    @ViewBuilder
    private func realityView(
        geometry: GeometryProxy
    ) -> some View {

        RealityView { content in

            content.add(viewModel.scene.rootEntity)

            viewModel.setRealityContent(content)
        }
        .padding(.top, topInset)
        .padding(.bottom, bottomInset)
        .clipped()
        .gesture(
            SpatialTapGesture()
                .onEnded { value in

                    let realityLocation = CGPoint(
                        x: value.location.x,
                        y: value.location.y - topInset
                    )

                    viewModel.scene.selectEntity(
                        at: realityLocation
                    )
                }
        )
        .gesture(
            TouchCounterView(
                tracker: touchTracker
            )
        )
        .simultaneousGesture(
            DragAndDropGesture(
                touchTracker: touchTracker,
                editViewModel: viewModel,
                scene: viewModel.scene
            ).dragGesture
        )
        .gesture(
            TwoFingerTransformGesture(
                touchTracker: touchTracker,
                entityProvider: { location in

                    let realityLocation = CGPoint(
                        x: location.x,
                        y: location.y - topInset
                    )

                    return viewModel.scene.entityAtScreenLocation(
                        realityLocation
                    )
                },
                editViewModel: viewModel,
                sceneController: viewModel.scene
            )
        )
    }

    // MARK: - Top Controls

    @ViewBuilder
    private func topControls(
        geometry: GeometryProxy
    ) -> some View {

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

    // MARK: - Editor Frame

    private func updateEditorFrame(
        geometry: GeometryProxy
    ) {

        let frame = geometry.frame(
            in: .global
        )

        let realityFrame = insetFrame(
            frame,
            topInset: topInset
        )

        viewModel.setEditorFrame(
            realityFrame
        )
    }

    // MARK: - Frame Helpers

    private func insetFrame(
        _ frame: CGRect,
        topInset: CGFloat
    ) -> CGRect {

        let bottom = max(
            0,
            min(
                bottomInset,
                frame.height - topInset
            )
        )

        let top = max(
            0,
            min(
                topInset,
                frame.height
            )
        )

        let height = max(
            0,
            frame.height - top - bottom
        )

        return CGRect(
            x: frame.minX,
            y: frame.minY + top,
            width: frame.width,
            height: height
        )
    }

    private func insetSize(
        _ size: CGSize
    ) -> CGSize {

        let top = min(
            max(0, topInset),
            size.height
        )

        let bottom = min(
            max(0, bottomInset),
            max(0, size.height - top)
        )

        return CGSize(
            width: size.width,
            height: max(
                0,
                size.height - top - bottom
            )
        )
    }

    // MARK: - Back

    private func handleBackTap() {

        if viewModel.hasUnsavedChanges {
            showUnsavedChangesAlert = true
        } else {
            vm.moveScreenState(to: .home)
        }
    }
}
