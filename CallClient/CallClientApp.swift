//
//  CallClientApp.swift
//  CallClient
//
//  Created by seungwooKim on 11/8/25.
//

import SwiftUI

@main
struct AiCallApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

//    @StateObject private var callManager = VapiCallManager.shared
    @State private var isInCallUI = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isInCallUI {
                    CallScreen()
                } else {
                    HomeView(onTestCall: {
                        isInCallUI = true
//                        callManager.startCall()
                    })
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .callKitDidAnswer)) { _ in
                // 유저가 잠금 화면에서 "수락" 눌렀을 때
                isInCallUI = true
//                callManager.startCall()   // ✅ 여기서 Vapi 콜 시작
            }
            .onReceive(NotificationCenter.default.publisher(for: .callKitDidEnd)) { _ in
                isInCallUI = false
//                callManager.stopCall()
            }
        }
    }
}
