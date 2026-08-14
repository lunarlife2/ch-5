//
//  SizeView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct SizeView: View {
    @State private var selectedHand: Hand = .right
    @State private var selectedFinger: Finger = .thumb
    @State private var selectedSystem: RingSizeSystem = .usCanada
    @State private var quantity = 1
    
    var body: some View {
        
        VStack {
            Picker("Finger", selection: $selectedFinger) {
                ForEach(Finger.allCases) { finger in
                    Text(finger.title)
                        .tag(finger)
                }
            }
            
            Picker("Hand", selection: $selectedHand) {
                ForEach(Hand.allCases) { hand in
                    Text(hand.title)
                        .tag(hand)
                }
            }
            
            VStack {
                Text("Materials")
                    .font(.system(size: 16, weight: .semibold))
                
                Stepper("\(quantity)", value: $quantity, in: 1...10)
                            .padding()
                
                Picker("System", selection: $selectedSystem) {
                    ForEach(RingSizeSystem.allCases) { system in
                        Text(system.title)
                            .tag(system)
                    }
                }
            }
        }
        
    }
}

#Preview {
    SizeView()
}
