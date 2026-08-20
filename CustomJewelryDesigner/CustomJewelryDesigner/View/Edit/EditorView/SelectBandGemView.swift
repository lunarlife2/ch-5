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
    var viewModel: EditViewModel

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
            
            VStack(alignment: .leading, spacing: 0) {

                Picker("", selection: $selectedType) {
                    Text("Band").tag(0)
                    Text("Gem").tag(1)
                    Text("Size").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)

                Group {
                    switch selectedType {
                    case 0:
                        BandView()

                    case 1:
                        GemView()

                    default:
                        SizeView(
                            bandGemViewModel: bandGemViewModel
                        )
                    }
                }
                .frame(
                    width: expandedWidth,
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
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
    }
}
