//
//  EditCard.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI

struct EditCard: View {
    var isSelected : Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                isSelected ? .white : .shadowSecondary
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? .black : .clear,
                        lineWidth: 2
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EditCard(isSelected: true)
}
