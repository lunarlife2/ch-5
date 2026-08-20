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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            //shape
            VStack(alignment: .leading) {
                Text("Shape")
                    .font(.system(size: 16, weight: .semibold))

                HStack {
                    ForEach(editViewModel.gemShapeOptions, id: \.self) { shape in

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
                            .frame(width: 40, height: 40)
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
                        .padding(.trailing, 15)
                        .onTapGesture {
                            selectedShape = shape
                            selectCombination()
                        }
                    }
                }
            }
            .padding(.bottom, 20)

            //material
            VStack(alignment: .leading) {
                Text("Materials")
                    .font(.system(size: 16, weight: .semibold))

                HStack {
                    ForEach(editViewModel.gemMaterialOptions, id: \.self) { material in

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
                            .frame(width: 40, height: 40)
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
                        .padding(.trailing, 15)
                        .onTapGesture {
                            selectedMaterial = material
                            selectCombination()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .disabled(editViewModel.isBandUpdating)
        .opacity(editViewModel.isBandUpdating ? 0.5 : 1)
        .overlay {
            if editViewModel.isBandUpdating {
                ProgressView("Updating…")
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .animation(.default, value: editViewModel.isBandUpdating)
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
