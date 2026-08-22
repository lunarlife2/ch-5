//
//  SizeView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI

struct SizeView: View {
    @Environment(ViewModel.self) private var vm
    
    @State private var ringSizeIndex = 0
    @Bindable var bandGemViewModel: BandGemViewModel
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            
            VStack(alignment: .leading) {
                //finger
                HStack {
                    Text("Finger")
                    
                    Spacer()
                    
                    Picker("", selection: $bandGemViewModel.selectedFinger) {
                        ForEach(Finger.allCases) { finger in
                            Text(finger.title)
                                .tag(finger)
                        }
                    }
                    .labelsHidden()
                    .tint(.secondary)
                }
                .padding(.horizontal, 30)
                
                Divider()
                    .frame(maxWidth: .infinity, maxHeight: 1)
                    .background(Color.black)
                    .padding(.horizontal, 30)
                
                //hand
                HStack {
                    Text("Hand")
                    
                    Spacer()
                    
                    Picker("", selection: $bandGemViewModel.selectedHand) {
                        ForEach(Hand.allCases) { hand in
                            Text(hand.title)
                                .tag(hand)
                        }
                    }
                    .tint(.secondary)
                    .labelsHidden()
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            
            
            //ring size
            VStack(alignment: .leading) {
                Text("Ring Size")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 10)
                
                //stepper
                Stepper("\(bandGemViewModel.selectedRingSizeSystem.title) \(bandGemViewModel.selectedRingSizeID)", value: $ringSizeIndex, in: 0...max(0, availableRingSizes.count - 1))
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                
                Divider()
                    .frame(maxWidth: .infinity, maxHeight: 1)
                    .background(Color.black)
                    .padding(.horizontal, 30)

                //system
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
                .padding(.horizontal, 30)
                
                Divider()
                    .frame(maxWidth: .infinity, maxHeight: 1)
                    .background(Color.black)
                    .padding(.horizontal, 30)

            }
            .onChange(of: bandGemViewModel.selectedRingSizeSystem) {
                ringSizeIndex = 0
                updateSelectedRingSize()
            }
            .onChange(of: ringSizeIndex) {
                updateSelectedRingSize()
            }
            
            //measure finger
            VStack{
                Button {
                    vm.moveScreenState(to: .measure)
                } label: {
                    Text("Measure Finger")
                }
                .padding(.vertical, 20)

            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        
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
