//
//  TesLoadGem.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 21/08/26.
//

import SwiftUI
import RealityKit

struct TesLoadGem: View {
    var body: some View {
        RealityView { content in
            do {
                let gem = try await Entity.load(named: "Chaos_Emerald")
                
                content.add(gem)
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    TesLoadGem()
}
