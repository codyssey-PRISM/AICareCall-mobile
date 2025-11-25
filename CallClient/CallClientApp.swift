//
//  CallClientApp.swift
//  CallClient
//
//  Created by seungwooKim on 11/8/25.
//

import ComposableArchitecture
import SwiftUI

@main
struct AiCallApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    static let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: Self.store)
                .onAppear {
                    // AppDelegate에게 Store 참조 전달
                    appDelegate.rootStore = Self.store
                }
        }
    }
}
