//
//  BandView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct BandView: View {
    //remove the enum state, use the variable from model
    @State private var selectedThickness: Double = 1
    @State private var isSelected = true
    @State private var selectedStyle: BandStyleEnum = .classic
    @State private var selectedMaterial: BandMaterialEnum = .yellowGold
    
    var body: some View {
        VStack(alignment: .leading) {
            //style
            VStack(alignment: .leading) {
                Text("Style")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack{
                    ForEach(BandStyleEnum.allCases) { style in
                        VStack{
                            Image("flat-2d")
                                .resizable()
                                .frame(maxWidth: 60, maxHeight: 60)
                                .padding()
                                .background(
                                    EditCard(isSelected: selectedStyle == style)
                                )
                                .draggable("Flat_Band_Ring")
                            
                            Text(style.title)
                                .font(.system(size: 12))
                        }
                        .padding(.trailing, 10)
                        .onTapGesture {
                            selectedStyle = style
                            print("Selected:", style)
                        }
                    }
                }
            }
            .padding()
            
            
            //thickness
            VStack(alignment: .leading) {
                Text("Thickness")
                    .font(.system(size: 16, weight: .semibold))

                Slider(
                    value: $selectedThickness,
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
            }
            .padding()
            .frame(maxWidth: 550)
            
            //material
            VStack(alignment: .leading) {
                Text("Materials")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack{
                    ForEach(BandMaterialEnum.allCases) { material in
                        VStack{
                            Image("flat-2d")
                                .resizable()
                                .frame(maxWidth: 60, maxHeight: 60)
                                .padding()
                                .background(
                                    EditCard(isSelected: selectedMaterial == material)
                                )
                                .draggable("Flat_Band_Ring")
                            
                            Text(material.title)
                                .font(.system(size: 12))
                        }
                        .padding(.trailing, 10)
                        .onTapGesture {
                            selectedMaterial = material
                            print("Selected:", material)
                        }
                    }
                }
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    BandView()
}
