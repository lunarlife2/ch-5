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
    var editViewModel: EditViewModel
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            Picker("", selection: bindingToHandFinger) {
                ForEach(HandFinger.allCases) { hf in
                    Text(hf.title)
                        .tag(hf)
                        .foregroundStyle(editViewModel.scene.isPlacementAvailable(for: hf) ? .primary : .secondary)
                }
            }
            
            //if the finger at the hand not measured yet
            VStack{
                Text("Not Measured yet")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray)
            )
            
            //if measured
            VStack {
                HStack {
                    Text("6.5")
                        .font(.system(size: 34, weight: .black))
                    
                    Button {
                        //edit measure (go to measure view)
                    } label: {
                        Image(systemName: "pencil")
                    }

                }
                Picker("", selection: $bandGemViewModel.selectedRingSizeSystem) {
                    ForEach(RingSizeSystem.allCases) { system in
                        Text(system.title)
                            .tag(system)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray)
            )
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
    
    private var bindingToHandFinger: Binding<HandFinger> {
        Binding(
            get: { editViewModel.selectedHandFinger },
            set: { newValue in
                guard editViewModel.scene.isPlacementAvailable(for: newValue) else { return }
                editViewModel.selectedHandFinger = newValue
            }
        )
    }
}
