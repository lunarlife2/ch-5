//
//  SelectBandGem.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 11/08/26.
//

import SwiftUI

struct SelectBandGemView: View {
    let panelWidth: CGFloat
    let expandedWidth: CGFloat
    let collapsedWidth: CGFloat
    @State private var selectedType = 0
    
    var body: some View {
        
        ZStack(alignment: .topTrailing) {
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
                .padding()
                
                if selectedType == 0 {
                    BandView()
                } else if selectedType == 1 {
                    GemView()
                } else {
                    SizeView()
                }

            }
            .frame(width: expandedWidth - collapsedWidth, alignment: .leading)

        }
        .frame(width: panelWidth, alignment: .leading)
        .clipped()
    }
    
}
//#Preview {
//    SelectBandGemView(p)
//}
