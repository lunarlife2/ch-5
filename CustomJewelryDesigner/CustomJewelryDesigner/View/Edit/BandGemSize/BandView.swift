//
//  BandView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct BandView: View {
    
    var viewModel: EditViewModel
    @State private var selectedStyle: BandStyle?
    @State private var sliderValue: Double = 1
    @State private var selectedMaterial: BandMaterialEnum? //still hardcode bcs we still not decide to make the asset or no
    
    var body: some View {
        
        VStack(alignment: .leading) {
            //Style
            VStack(alignment: .leading) {
                Text("Style")
                    .font(.system(size: 16, weight: .semibold))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(
                            viewModel.uniqueBandsByStyle,
                            id: \.id
                        ) { band in
                            VStack {
                                AsyncImage(url: viewModel.thumbnailURL(for: band.assetId)) { phase in
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
                                .onAppear {
                                    print("Thumbnail URL:", viewModel.thumbnailURL(for: band.assetId)?.absoluteString ?? "nil")
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
                                Text(
                                    band.bandStyleID.bandStyleName
                                )
                                .font(.system(size: 12))
                            }
                            .padding(.trailing, 10)
                            .onTapGesture {
                                selectedStyle = band.bandStyleID
                                Task {
                                    await viewModel.selectBand(
                                        style: band.bandStyleID,
                                        thickness: viewModel.thicknessLabel(forSliderValue: sliderValue)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            
            //Thickness already work if user choose the thickness, the asset will showing the right asset
            VStack(alignment: .leading) {
                Text("Thickness")
                    .font(.system(size: 16, weight: .semibold))
                Slider(
                    value: $sliderValue,
                    in: 1...3,
                    step: 1
                )
                .onChange(of: sliderValue) { _, newValue in
                    let thickness = viewModel.thicknessLabel(forSliderValue: newValue)
                    if let style = selectedStyle {
                        Task {
                            await viewModel.selectBand(style: style, thickness: thickness)
                        }
                    }
                }
            }
            
            Text(
                viewModel
                    .thicknessLabel(
                        forSliderValue:
                            sliderValue
                    )
                    .capitalized
            )
            .font(.caption)
            
        }
        .padding()
        .frame(maxWidth: 550)
        
        //Material still hardcode and doesn't work yet
        VStack(alignment: .leading) {
            Text("Materials")
                .font(.system(size: 16, weight: .semibold))
            HStack {
                ForEach(
                    BandMaterialEnum.allCases
                ) { material in
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
                                        selectedMaterial
                                    == material
                                )
                            )
                        
                        Text(material.title)
                            .font(.system(size: 12))
                    }
                    .padding(.trailing, 10)
                    .onTapGesture {
                        
                        selectedMaterial =
                        material
                        
                        print(
                            "Selected:",
                            material
                        )
                    }
                }
            }
        }
        //        .padding()
        .padding()
        .onAppear {
            
            if selectedStyle == nil {
                
                selectedStyle =
                viewModel.defaultBandStyle
            }
            
            
            //thickness already work to change the asset on database
            if let thickness =
                viewModel.defaultBandThickness {
                
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
}

#Preview {
    BandView(
        viewModel: EditViewModel()
    )
}
