//
//  SnappingPointView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 20/08/26.
//

import SwiftUI

struct SnappingPointView: View {
    let isOccupied: Bool
    
    var body: some View {
        Circle()
            .fill(isOccupied ? Color.gray : Color.blue)
            .frame(width: 24, height: 24)
            .shadow(radius: 3)
            .opacity(0.5)
    }
}

#Preview {
    SnappingPointView(isOccupied: true)
}
