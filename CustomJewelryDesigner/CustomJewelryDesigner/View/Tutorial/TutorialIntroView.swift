//
//  TutorialIntroView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//

import SwiftUI

struct TutorialIntroView: View {
    var onStart: () -> Void
    @State private var page = 0

//    private let pages: [(icon: String, title: String, text: String)] = [
//        ("wand.and.stars", "Selamat datang!", "Yuk kenalan dulu sama fitur utamanya sebelum mulai mendesain perhiasanmu sendiri."),
//        ("hand.draw", "Gesture Dasar", "Kamu bisa memutar objek, ganti band, dan nambahin gem langsung di layar desain."),
//        ("hand.raised", "Coba di File Contoh", "Kita buatkan satu file contoh bernama \"Tutorial\" biar kamu bisa langsung praktik.")
//    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            HStack(spacing: 24) {
                Text("Image snippet of workshop/ring")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Color.tutorialPrimary,
                        in: UnevenRoundedRectangle(
                            topLeadingRadius: 20,
                            bottomLeadingRadius: 20,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )

                VStack(spacing: 40) {
                    Image(systemName: "xmark")
                        .frame(maxWidth: .infinity, alignment: .topTrailing)

                    Text("Design your first ring")
                        .font(.system(size: 20, weight: .regular))

                    Button {
                        onStart()
                    } label: {
                        Text("Start Tutorial")
                            .font(.system(size: 17))
                            .padding(.horizontal, 44)
                            .padding(.vertical, 10)
                    }
                    .tint(Color.appPrimary)
                    .buttonStyle(.glassProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
            }
            
            .frame(width: 597, height: 300)
            .background(
                Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .clipped()
            .shadow(radius: 30)
        }
    }
}
