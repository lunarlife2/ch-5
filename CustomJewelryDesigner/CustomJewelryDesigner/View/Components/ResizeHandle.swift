//
//  ResizeHandle.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//
import SwiftUI

struct ResizeHandle: View {
    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.25)
            .stroke(
                Color.black,
                style: StrokeStyle(
                    lineWidth: 8,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: 30, height: 30)
            .scaleEffect(x: -1, y: 1)
            .contentShape(Rectangle())
    }
}
#Preview {
    ResizeHandle()
}
