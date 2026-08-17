//
//  SelectBandGem.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 11/08/26.
//

import SwiftUI

struct SelectBandGemView: View {
    @State private var selectedType = 0
    @Bindable var bandGemViewModel: BandGemViewModel
    
    let panelWidth: CGFloat
    let expandedWidth: CGFloat
    let collapsedWidth: CGFloat
    
    private var collapseOffset: CGFloat {
        expandedWidth - panelWidth
    }
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.shadowTertiary)
                .frame(width: expandedWidth)

            VStack(alignment: .leading, spacing: 0) {
                Picker("", selection: $selectedType) {
                    Text("Band").tag(0)
                    Text("Gem").tag(1)
                    Text("Size").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(20)
                .padding(.top, 10)

                Group {
                    if selectedType == 0 {
                        BandView()
                    } else if selectedType == 1 {
                        GemView()
                    } else {
                        SizeView(bandGemViewModel: bandGemViewModel)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
            }
            .frame(
                width: expandedWidth,
                alignment: .topLeading
            )
            .offset(x: collapseOffset)
        }
        .frame(
            width: panelWidth,
            alignment: .topLeading
        )
        .clipped()
    }
}


//#Preview {
//    @Previewable @State var viewModel = BandGemViewModel()
//    
//    SelectBandGemView(panelWidth: 508, expandedWidth: 508, collapsedWidth: 40, viewModel: viewModel)
//}
