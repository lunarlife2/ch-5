//
//  BandView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct BandView: View {
    @Environment(EditViewModel.self) private var editViewModel
    @State private var selectedStyle: BandStyle?
    @State private var sliderValue: Double = 1
    @State private var selectedMaterial: BandMaterialEnum = .yellowGold

    private var currentThicknessLabel: String {
        editViewModel.thicknessLabel(forSliderValue: sliderValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // style
            VStack(alignment: .leading, spacing: 10) {
                Text("Style")
                    .font(.appFont(size: 16, weight: .semibold))

                HStack {
                    ForEach(editViewModel.uniqueBandsByStyle, id: \.id) { band in
                        VStack {
                            AsyncImage(url: editViewModel.thumbnailURL(for: band.assetId)) { phase in
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
                            .frame(width: 40, height: 40)
                            .padding()
                            .background(
                                EditCard(isSelected: selectedStyle?.id == band.bandStyleID.id)
                            )

                            Text(band.bandStyleID.bandStyleName)
                                .font(.appFont(size: 12))
                        }
                        .padding(.trailing, 17)
                        .onTapGesture {
                            selectedStyle = band.bandStyleID
                            Task {
                                await editViewModel.selectBand(
                                    style: band.bandStyleID,
                                    thickness: currentThicknessLabel,
                                    material: selectedMaterial
                                )
                            }
                        }
                    }
                }
            }
            
            Divider()
                .padding(.trailing, 20)
            
            // thickness
            VStack(alignment: .leading, spacing: 10) {
                Text("Thickness")
                    .font(.appFont(size: 16, weight: .semibold))

                Slider(value: $sliderValue, in: 1...3, step: 1) {
                    Text("Thickness")
                } minimumValueLabel: {
                    Text("Thin").font(.appFont(size: 12))
                } maximumValueLabel: {
                    Text("Thick").font(.appFont(size: 12))
                }
            }
            .padding(.trailing, 20)

            Divider()
                .padding(.trailing, 20)
            
            // material
            VStack(alignment: .leading, spacing: 10) {
                Text("Materials")
                    .font(.appFont(size: 16, weight: .semibold))

                HStack {
                    ForEach(BandMaterialEnum.allCases) { material in
                        let matchedBand = editViewModel.band(
                            forStyle: selectedStyle,
                            thickness: currentThicknessLabel,
                            material: material
                        )
                        let isAvailable = matchedBand != nil

                        VStack {
                            AsyncImage(url: matchedBand.flatMap { editViewModel.thumbnailURL(for: $0.assetId) }) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.secondary)
                                case .empty:
                                    if isAvailable {
                                        ProgressView()
                                    } else {
                                        Image("flat-2d").resizable().scaledToFit()
                                    }
                                @unknown default:
                                    ProgressView()
                                }
                            }
                            .frame(width: 40, height: 40)
                            .padding()
                            .background(EditCard(isSelected: selectedMaterial == material))
                            .opacity(isAvailable ? 1 : 0.4)

                            Text(material.title)
                                .font(.appFont(size: 12))
                        }
                        .padding(.trailing, 17)
                        .onTapGesture {
                            guard isAvailable, let style = selectedStyle else { return }
                            selectedMaterial = material
                            Task {
                                await editViewModel.selectBand(
                                    style: style,
                                    thickness: currentThicknessLabel,
                                    material: material
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: 550)
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
            setupInitialSelection()
        }
        .onChange(of: sliderValue) { _, newValue in
            guard let style = selectedStyle else { return }
            let thickness = editViewModel.thicknessLabel(forSliderValue: newValue)
            Task {
                await editViewModel.selectBand(style: style, thickness: thickness, material: selectedMaterial)
            }
        }
    }

    private func setupInitialSelection() {
        if selectedStyle == nil {
            selectedStyle = editViewModel.defaultBandStyle
        }
        if let style = editViewModel.selectedBandStyle {
            selectedStyle = style
        } else {
            selectedStyle = editViewModel.defaultBandStyle
        }
        
        if let material = editViewModel.selectedBandMaterial {
            selectedMaterial = material
        } else {
            selectedMaterial =
            editViewModel.defaultBandMaterial ?? .yellowGold
        }
        
        if let thickness = editViewModel.selectedBandThickness {
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
        } else {
            sliderValue = 1
        }
    }
}

