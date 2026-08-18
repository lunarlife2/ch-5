//
//  GemView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

//
//  GemView.swift
//  CustomJewelryDesigner
//

import SwiftUI

struct GemView: View {
    @Environment(EditViewModel.self) private var editViewModel

    @State private var selectedShape: String?
    @State private var selectedMaterial: String?

    var body: some View {
        VStack(alignment: .leading) {

            //shape
            VStack(alignment: .leading) {
                Text("Shape")
                    .font(.system(size: 16, weight: .semibold))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(
                            editViewModel.gemShapeOptions,
                            id: \.self
                        ) { shape in

                            let representative = editViewModel.gems.first {
                                $0.gemShape.caseInsensitiveCompare(shape)
                                    == .orderedSame
                            }

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
                                .frame(width: 60, height: 60)
                                .padding()
                                .background(
                                    EditCard(
                                        isSelected:
                                            selectedShape == shape
                                    )
                                )

                                Text(shape.capitalized)
                                    .font(.system(size: 12))
                            }
                            .padding(.trailing, 10)
                            .onTapGesture {
                                selectedShape = shape
                                selectCombination()
                            }
                        }
                    }
                }
            }
            .padding()

            //material
            VStack(alignment: .leading) {
                Text("Materials")
                    .font(.system(size: 16, weight: .semibold))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(
                            editViewModel.gemMaterialOptions,
                            id: \.self
                        ) { material in

                            let representative = editViewModel.gems.first {
                                $0.gemMaterial.caseInsensitiveCompare(material)
                                    == .orderedSame
                            }

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
                                .frame(width: 60, height: 60)
                                .padding()
                                .background(
                                    EditCard(
                                        isSelected:
                                            selectedMaterial == material
                                    )
                                )

                                Text(material.capitalized)
                                    .font(.system(size: 12))
                            }
                            .padding(.trailing, 10)
                            .onTapGesture {
                                selectedMaterial = material
                                selectCombination()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding()
        .onAppear {
            applyDefaultsIfNeeded()
        }
        .onChange(of: editViewModel.gems.count) { _, _ in
            applyDefaultsIfNeeded()
        }
    }

    //default selection
    private func applyDefaultsIfNeeded() {
        if selectedShape == nil {
            selectedShape = editViewModel.defaultGemShape
        }

        if selectedMaterial == nil {
            selectedMaterial = editViewModel.defaultGemMaterial
        }

        selectCombination()
    }

    //select gem combination
    private func selectCombination() {
        guard
            let shape = selectedShape,
            let material = selectedMaterial
        else {
            return
        }

        Task {
            await editViewModel.selectGem(
                shape: shape,
                material: material
            )
        }
    }
}

//#Preview {
//    GemView(
//        viewModel: EditViewModel()
//    )
//}
