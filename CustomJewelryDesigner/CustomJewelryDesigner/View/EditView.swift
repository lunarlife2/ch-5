//
//  EditView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI

struct EditView: View {
    @State private var editViewModel = EditViewModel()
    @State private var panelWidth: CGFloat = 508
    @State private var dragStartWidth: CGFloat = 508

    private let expandedWidth: CGFloat = 508
    private let collapsedWidth: CGFloat = 20
    private let collapseDistanceThreshold: CGFloat = 90
    private let screenMargin: CGFloat = 20
    
    private var expandProgress: CGFloat {
        let range = expandedWidth - collapsedWidth
        guard range > 0 else { return 0 }
        return (panelWidth - collapsedWidth) / range
    }

    var body: some View {
        HStack(spacing: 0) {
            JewelryEditorView(viewModel: editViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            SelectBandGemView(viewModel: editViewModel,panelWidth: panelWidth, expandedWidth: expandedWidth, collapsedWidth: collapsedWidth
            )
            .task {
                await editViewModel.fetchAllData()

                print("Band:", editViewModel.bands.count)
                print("Gem:", editViewModel.gems.count)
                print("Style:", editViewModel.bandStyles.count)
            }
            
            .frame(width: panelWidth, height: 558)
            .padding(.trailing, screenMargin * expandProgress)
            .overlay(alignment: .bottomLeading) {
                ResizeHandle()
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newWidth = dragStartWidth - value.translation.width
                                panelWidth = min(
                                    expandedWidth,
                                    max(collapsedWidth, newWidth)
                                )
                            }
                            .onEnded { value in
                                withAnimation(.smooth) {
                                    if value.translation.width > collapseDistanceThreshold {
                                        panelWidth = collapsedWidth
                                    } else {
                                        panelWidth = expandedWidth
                                    }
                                    dragStartWidth = panelWidth
                                }
                            }
                    )
            }
        }
    }
}


#Preview {
    EditView()
}
