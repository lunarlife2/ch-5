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
    @State private var ringSizeIndex = 0
    
    @Bindable var bandGemViewModel: BandGemViewModel
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Text("Finger")
                
                Spacer()
                
                Picker("", selection: $selectedFinger) {
                    ForEach(Finger.allCases) { finger in
                        Text(finger.title)
                            .tag(finger)
                    }
                }
                .labelsHidden()
                .tint(.secondary)
            }
            .padding(.top, 30)
            .padding(.horizontal, 50)
            
            Divider()
                .frame(maxWidth: .infinity, maxHeight: 1)
                .background(Color.black)
                .padding(.horizontal, 50)
            
            HStack {
                Text("Hand")
                
                Spacer()
                
                Picker("", selection: $selectedHand) {
                    ForEach(Hand.allCases) { hand in
                        Text(hand.title)
                            .tag(hand)
                    }
                }
                .tint(.secondary)
                .labelsHidden()
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 30)
            
            
            VStack(alignment: .leading) {
                Text("Ring Size")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 30)
                
                Stepper("\(bandGemViewModel.selectedRingSizeSystem.title) \(bandGemViewModel.selectedRingSizeID)", value: $ringSizeIndex, in: 0...max(0, availableRingSizes.count - 1))
                    .padding(.horizontal, 50)
                    .padding(.top, 20)
                
                Divider()
                    .frame(maxWidth: .infinity, maxHeight: 1)
                    .background(Color.black)
                    .padding(.horizontal, 50)

                
                HStack {
                    Text("System")
                    
                    Spacer()
                    
                    Picker("", selection: $bandGemViewModel.selectedRingSizeSystem) {
                        ForEach(RingSizeSystem.allCases) { system in
                            Text(system.title)
                                .tag(system)
                        }
                    }
                    .tint(.secondary)
                    .labelsHidden()
                }
                .padding(.horizontal, 50)
                
                Divider()
                    .frame(maxWidth: .infinity, maxHeight: 1)
                    .background(Color.black)
                    .padding(.horizontal, 50)

            }
            .onChange(of: bandGemViewModel.selectedRingSizeSystem) {
                ringSizeIndex = 0
                updateSelectedRingSize()
            }
            .onChange(of: ringSizeIndex) {
                updateSelectedRingSize()
            }
            VStack{
                Button {
                    //measure finger using VM
                } label: {
                    Text("Measure Finger")
                }
                .padding(.vertical, 20)

            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        
    }
    
    private var availableRingSizes: [RingSizeOption] {
        ringSizeOptions.filter {
            $0.size(for: bandGemViewModel.selectedRingSizeSystem) != nil
        }
    }
    
    private func updateSelectedRingSize() {
        guard availableRingSizes.indices.contains(ringSizeIndex) else {
            return
        }
        
        bandGemViewModel.selectedRingSizeID = availableRingSizes[ringSizeIndex].id
    }
}
