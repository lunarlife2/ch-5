//
//  HandSizeView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 21/08/26.
//

import SwiftUI
import SwiftData

struct HandSizeView: View {
	@Environment(ViewModel.self) private var vm
	@Environment(\.modelContext) private var modelContext
	
	
	var body: some View {
		ZStack {
			VStack{
				Text("Hand Profile")
					.font(.title)
				Text("Save your measurements and tone for quick virtual try-ons.")
					.font(.system(size: 17, weight: .regular))
					.foregroundStyle(Color.gray)
				
				Spacer()
				
				

			}
			.padding(.horizontal, 100)
			.padding(.top, 20)
			
			Button {
				vm.moveScreenState(to: .home)
			} label: {
				Image(systemName: "chevron.left")
					.foregroundStyle(Color.black)
					.controlSize(.large)
			}
			.clipShape(.circle)
			.buttonStyle(.glass)
			.controlSize(.large)
			.shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 0)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
			.padding(.all, 50)

		}
	}
}

#Preview {
	HandSizeView()
		.environment(ViewModel())
}
