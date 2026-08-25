//
//  CreateFileSheet.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//


// CreateFileSheet.swift
import SwiftUI

struct CreateFileSheet: View {
    @State private var fileName: String = ""
    var onCancel: () -> Void
    var onCreate: (String) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("File Name")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Button { onCancel() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.appPrimary)
                }
            }

            TextField("File name", text: $fileName)
                .textFieldStyle(.roundedBorder)

            Button {
                guard !fileName.isEmpty else { return }
                onCreate(fileName)
            } label: {
                Text("Create").frame(maxWidth: .infinity)
            }
            .tint(Color.appPrimary)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shadow(radius: 20)
        .frame(width: 400)
    }
}
