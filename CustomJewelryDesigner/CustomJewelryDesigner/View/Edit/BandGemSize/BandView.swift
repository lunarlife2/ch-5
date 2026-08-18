//
//  BandView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct BandView: View {
    //remove the enum state, use the variable from model
    @Environment(EditViewModel.self) private var editViewModel
    @State private var selectedThickness: Double = 1
    @State private var isSelected = true
    @State private var selectedStyle: BandStyle?
    @State private var sliderValue: Double = 1
    @State private var selectedMaterial: BandMaterialEnum? //still hardcode bcs we still not decide to make the asset or no
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // style
            VStack(alignment: .leading, spacing: 10) {
                Text("Style")
                    .font(.system(size: 16, weight: .semibold))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(
                            editViewModel.uniqueBandsByStyle,
                            id: \.id
                        ) { band in
                            
                            VStack {
                                AsyncImage(
                                    url: editViewModel.thumbnailURL(
                                        for: band.assetId
                                    )
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
                                            selectedStyle?.id
                                        == band.bandStyleID.id
                                    )
                                )
                                
                                Text(band.bandStyleID.bandStyleName)
                                    .font(.system(size: 12))
                            }
                            .padding(.trailing, 10)
                            .onTapGesture {
                                selectedStyle = band.bandStyleID
                                
                                Task {
                                    await editViewModel.selectBand(
                                        style: band.bandStyleID,
                                        thickness:
                                            editViewModel.thicknessLabel(
                                                forSliderValue: sliderValue
                                            )
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            //thickness alr works
            VStack(alignment: .leading, spacing: 10) {
                Text("Thickness")
                    .font(.system(size: 16, weight: .semibold))
                
                Slider(
                    value: $sliderValue,
                    in: 1...3,
                    step: 1
                ) {
                    Text("Thickness")
                } minimumValueLabel: {
                    Text("Thin")
                        .font(.system(size: 12))
                } maximumValueLabel: {
                    Text("Thick")
                        .font(.system(size: 12))
                }
                
                Text(
                    editViewModel
                        .thicknessLabel(
                            forSliderValue: sliderValue
                        )
                        .capitalized
                )
                .font(.caption)
            }
            .frame(maxWidth: 550)
            
            //material
            VStack(alignment: .leading, spacing: 10) {
                Text("Materials")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack {
                    ForEach(BandMaterialEnum.allCases) { material in
                        VStack {
                            Image("flat-2d")
                                .resizable()
                                .frame(
                                    maxWidth: 60,
                                    maxHeight: 60
                                )
                                .padding()
                                .background(
                                    EditCard(
                                        isSelected:
                                            selectedMaterial == material
                                    )
                                )
                            
                            Text(material.title)
                                .font(.system(size: 12))
                        }
                        .padding(.trailing, 10)
                        .onTapGesture {
                            selectedMaterial = material
                            print("Selected material:", material)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: 550)
        
        // MARK: - Initial State
        
        .onAppear {
            setupInitialSelection()
        }
        
        // MARK: - Thickness Changed
        
        .onChange(of: sliderValue) { _, newValue in
            guard let style = selectedStyle else {
                return
            }
            
            let thickness = editViewModel.thicknessLabel(
                forSliderValue: newValue
            )
            
            Task {
                await editViewModel.selectBand(
                    style: style,
                    thickness: thickness
                )
            }
        }
    }
    
    private func setupInitialSelection() {
        if selectedStyle == nil {
            selectedStyle = editViewModel.defaultBandStyle
        }
        
        if let thickness = editViewModel.defaultBandThickness {
            switch thickness.lowercased() {
            case "thin":
                sliderValue = 1
                
            case "medium":
                sliderValue = 2
                
            case "thick":
                sliderValue = 3
                
            default:
                sliderValue = 1
            }
        }
    }
}

//#Preview {
//    BandView(
//        viewModel: EditViewModel()
//    )
//}
