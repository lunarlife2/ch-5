//
//  SelectBandGem.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 11/08/26.
//

import SwiftUI

struct SelectBandGemView: View {

    @Binding var selectedType: Int
    @Bindable var bandGemViewModel: BandGemViewModel
    var viewModel: EditViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.mode != .handMannequin {
                Picker("", selection: $selectedType) {
                    Text("Band").tag(0)
                    Text("Gem").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
            }

            Group {
                if viewModel.mode == .handMannequin {
                    MannequinView(viewModel: viewModel)
                } else {
                    switch selectedType {
                    case 0:
                        BandView()
                    case 1:
                        GemView()
                    default:
                        BandView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
