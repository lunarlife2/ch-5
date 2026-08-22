//
//  SelectSkinSizeView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 22/08/26.
//

import SwiftUI

struct SelectSkinSizeView: View {
    
    @Binding var selectedType: Int
    @Bindable var bandGemViewModel: BandGemViewModel
    var viewModel: EditViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.mode != .band {
                Picker("", selection: $selectedType) {
                    Text("Skin").tag(0)
                    Text("Size").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
            }

            Group {
                if viewModel.mode == .band {
                    BandView()
                } else {
                    switch selectedType {
                    case 0:
                        SkinView(
                            initialColor: viewModel.skinColor,
                            onPreview: { color in
                                viewModel.setSkinColor(color)
                            },
                            editViewModel: viewModel
                        )
                    case 1:
                        SizeView(bandGemViewModel: bandGemViewModel, editViewModel: viewModel)
                    default:
                        SkinView(
                            initialColor: viewModel.skinColor,
                            onPreview: { color in
                                viewModel.setSkinColor(color)
                            },
                            editViewModel: viewModel
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
