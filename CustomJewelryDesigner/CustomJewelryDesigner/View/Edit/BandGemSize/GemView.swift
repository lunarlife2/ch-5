//
//  GemView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct GemView: View {
    var viewModel: EditViewModel
    // Shape & material from supabase
    @State private var selectedShape: String?
    @State private var selectedMaterial: String?
    @State private var isSelected = true
    
    
    var body: some View {
        VStack(alignment: .leading) {
            //shape
            VStack(alignment: .leading) {
                Text("Shape")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack{
                    ForEach(viewModel.gemShapeOptions, id: \.self) { shape in
                        let representative = viewModel.gems.first{
                            $0.gemShape.caseInsensitiveCompare(shape) == .orderedSame
                        }
                        VStack{
                            AsyncImage(url: representative.flatMap { viewModel.thumbnailURL(for: $0.assetId) }) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.secondary)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    ProgressView()
                                }
                            }
                            .frame(maxWidth: 60, maxHeight: 60)
                            .padding()
                            .background(
                                EditCard(isSelected: selectedShape == shape)
                            )
                            .draggable("Gemstone")
                            
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
            .padding()
            
            //material
            VStack(alignment: .leading) {
                Text("Materials")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack{
                    ForEach(viewModel.gemMaterialOptions, id: \.self) { material in
                        let representative = viewModel.gems.first{
                            $0.gemMaterial.caseInsensitiveCompare(material) == .orderedSame
                        }
                        VStack{
                            AsyncImage(url: representative.flatMap { viewModel.thumbnailURL(for: $0.assetId) }) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.secondary)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    ProgressView()
                                }
                            }
                            .frame(maxWidth: 60, maxHeight: 60)
                            .padding()
                            .background(
                                EditCard(isSelected: selectedMaterial == material)
                            )
                            .draggable("Gemstone")
                        
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
            .padding()
        }
        .padding()
        .onAppear {
            applyDefaultsIfNeeded()
        }
        .onChange(of: viewModel.gems.count) { _, _ in
            applyDefaultsIfNeeded()
        }
    }
    private func applyDefaultsIfNeeded() {
        if selectedShape == nil {
            selectedShape = viewModel.defaultGemShape
        }
        if selectedMaterial == nil {
            selectedMaterial = viewModel.defaultGemMaterial
        }
        selectCombination()
    }
    
    
    private func selectCombination() {
        guard let shape = selectedShape, let material = selectedMaterial else {
            return
        }
        Task {
            await viewModel.selectGem(shape: shape, material: material)
        }
    }
}

#Preview {
    GemView(
        viewModel: EditViewModel()
    )
}
