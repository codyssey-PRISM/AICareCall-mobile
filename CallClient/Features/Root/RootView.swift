//
//  RootView.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import SwiftUI

struct RootView: View {    
    @Bindable var store: StoreOf<RootFeature>

    var body: some View {
        Group {
            switch store.scope(state: \.destination, action: \.destination).case {
            case let .splash(store):
                SplashView(store: store)
                
            case let .home(store):
                HomeView(store: store)
                
            case let .call(store):
                CallView(store: store)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}
