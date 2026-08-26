//
//  GemView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct GemView: View {
    @Environment(EditViewModel.self) private var editViewModel

    @State private var selectedShape: String?
    @State private var selectedMaterial: String?
    
    @State private var isAdding = false

    private var canAddGem: Bool {
        selectedShape != nil && selectedMaterial != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            //shape
            VStack(alignment: .leading) {
                Text("Shape")
                    .font(.appFont(size: 16, weight: .semibold))

                HStack {
                    ForEach(editViewModel.gemShapeOptions, id: \.self) { shape in

                        let representative = editViewModel.gem(forShape: shape)

                        VStack {
                            AsyncImage(
                                url: representative.flatMap {
                                    editViewModel.thumbnailURL(
                                        for: $0.assetId
                                    )
                                }
                            ) { phase in

                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()

                                case .failure:
                                    Image(
                                        systemName:
                                            "exclamationmark.triangle"
                                    )
                                    .foregroundStyle(.secondary)

                                case .empty:
                                    ProgressView()

                                @unknown default:
                                    ProgressView()
                                }
                            }
                            .frame(width: 40, height: 40)
                            .padding()
                            .background(
                                EditCard(isSelected: selectedShape == shape)
                            )

                            Text(shape.capitalized)
                                .font(.appFont(size: 12))
                        }
                        .padding(.trailing, 15)
                        .onTapGesture {
                            selectedShape = shape
                            selectedMaterial = nil
                        }
                    }
                }
            }
            .padding(.bottom, 20)
            
            Divider()

            //material
            VStack(alignment: .leading) {
                Text("Materials")
                    .font(.appFont(size: 16, weight: .semibold))

                HStack {
                    ForEach(editViewModel.gemMaterialOptions, id: \.self) { material in

                        let representative = editViewModel.gem(forShape: selectedShape, material: material)

                        let isAvailable = representative != nil

                        VStack {
                            AsyncImage(
                                url: representative.flatMap {
                                    editViewModel.thumbnailURL(
                                        for: $0.assetId
                                    )
                                }
                            ) { phase in

                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()

                                case .failure:
                                    Image(
                                        systemName:
                                            "exclamationmark.triangle"
                                    )
                                    .foregroundStyle(.secondary)

                                case .empty:
//                                    ProgressView()
                                    if isAvailable {
                                        ProgressView()
                                    } else {
                                        Image("gemstone-blue").resizable().scaledToFit()
                                    }

                                @unknown default:
                                    ProgressView()
                                }
                            }
                            .frame(width: 40, height: 40)
                            .padding()
                            .background(EditCard(isSelected: selectedMaterial == material))
                            .opacity(isAvailable ? 1 : 0.4)

                            Text(material.capitalized)
                                .font(.appFont(size: 12))
                        }
                        .padding(.trailing, 15)
                        .onTapGesture {
                            guard isAvailable else { return }
                            selectedMaterial = material
                        }
                    }
                }
            }
            
            Divider()
            
            if canAddGem {
                Button {
                    addGem()
                } label: {
                    HStack {
                        Spacer()

                        if isAdding {
                            ProgressView()
                        } else {
                            Text("Add Gem")
                        }

                        Spacer()
                    }
                }
                .tint(Color.appPrimary)
                .buttonStyle(.glassProminent)
                .controlSize(.mini)
                .disabled(isAdding)
            } else {
                Button {
                    addGem()
                } label: {
                    HStack {
                        Spacer()

                        if isAdding {
                            ProgressView()
                        } else {
                            Text("Add Gem")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(true)
            }

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: 550)
    }

    private func addGem() {
        guard let shape = selectedShape, let material = selectedMaterial, !isAdding else { return }
        isAdding = true
        Task {
            await editViewModel.selectGem(shape: shape, material: material)
            isAdding = false
            // reset so picking the next gem starts from a clean slate,
            // instead of leaving a stale combo ready to be re-added
            selectedShape = nil
            selectedMaterial = nil
        }
    }
}
            
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 20)
//        .disabled(editViewModel.isBandUpdating)
//        .opacity(editViewModel.isBandUpdating ? 0.5 : 1)
//        .overlay {
//            if editViewModel.isBandUpdating {
//                ProgressView("Updating…")
//                    .padding()
//                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
//            }
//        }
//        .animation(.default, value: editViewModel.isBandUpdating)
//        .onAppear {
//            applyDefaultsIfNeeded()
//        }
//        .onChange(of: editViewModel.gems.count) { _, _ in
//            applyDefaultsIfNeeded()
//        }
//    }
//
//    //default selection
//    private func applyDefaultsIfNeeded() {
//        if selectedShape == nil {
//            selectedShape = editViewModel.defaultGemShape
//        }
//
//        if selectedMaterial == nil {
//            selectedMaterial = editViewModel.defaultGemMaterial
//        }
//
//        selectCombination()
//    }
//
//    //select gem combination
//    private func selectCombination() {
//        guard
//            let shape = selectedShape,
//            let material = selectedMaterial
//        else {
//            return
//        }
//
//        Task {
//            await editViewModel.selectGem(
//                shape: shape,
//                material: material
//            )
//        }
//    }
//    
//    
//}

#Preview {
    let design = Design(
        materialPreset: "Yellow Gold",
        gems: []
    )
    
    let designFile = DesignFile(
        id: UUID(),
        name: "Preview Design",
        updatedAt: .now,
        ringPosition: .left,
        design: design
    )
    
    let viewModel = EditViewModel(
        designFile: designFile
    )
    
    GemView()
        .environment(viewModel)
}
