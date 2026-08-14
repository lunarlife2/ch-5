//
//  GemView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct GemView: View {
    //remove the enum state, use the variable from model
    @State private var selectedThickness: Double = 1
    @State private var isSelected = true
    @State private var selectedShape: GemShapeEnum = .round
    @State private var selectedMaterial: GemMaterialEnum = .diamond
    
    var body: some View {
        VStack(alignment: .leading) {
            //style
            VStack(alignment: .leading) {
                Text("Shape")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack{
                    ForEach(GemShapeEnum.allCases) { shape in
                        VStack{
                            Image("gemstone-blue")
                                .resizable()
                                .frame(maxWidth: 60, maxHeight: 60)
                                .padding()
                                .background(
                                    EditCard(isSelected: selectedShape == shape)
                                )
                                .draggable("Gemstone")
                            
                            Text(shape.title)
                                .font(.system(size: 12))
                        }
                        .padding(.trailing, 10)
                        .onTapGesture {
                            selectedShape = shape
                            print("Selected:", shape)
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
                    ForEach(GemMaterialEnum.allCases) { material in
                        VStack{
                            Image("gemstone-blue")
                                .resizable()
                                .frame(maxWidth: 60, maxHeight: 60)
                                .padding()
                                .background(
                                    EditCard(isSelected: selectedMaterial == material)
                                )
                                .draggable("Gemstone")
                            
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
    GemView()
}
