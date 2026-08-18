//
//  MannequinView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 18/08/26.
//

import SwiftUI

struct MannequinView: View {
    @State private var selectedFinger: Finger = .thumb
    var body: some View {
        VStack {
            //choose finger
            VStack {
                Text("Choose Finger")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 30)
                
                Picker("", selection: $selectedFinger) {
                    ForEach(Finger.allCases) { system in
                        Text(system.title)
                            .tag(system)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            //choose skin color
            VStack {
                Text("Choose Skin Color")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 30)
                
                HStack {
                    
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

#Preview {
    MannequinView()
}
