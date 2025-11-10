//
//  CallScreen.swift
//  CallClient
//
//  Created by seungwooKim on 11/10/25.
//


// MARK: - CallScreen
import SwiftUI

struct CallScreen: View {
//    @StateObject private var callManager = VapiCallManager.shared

    var body: some View {
        VStack(spacing: 24) {
            
            Text("Call Screen")
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true) // 원하면 뒤로가기 막기
    }
}
