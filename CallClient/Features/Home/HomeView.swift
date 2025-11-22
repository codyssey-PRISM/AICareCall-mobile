//
//  HomeView.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        VStack(spacing: 24) {
            Text("AI Call Demo")
                .font(.largeTitle.bold())

            Text("아래 버튼을 눌러 AI와 테스트 통화를 시작해보세요.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button {
                store.send(.startCallButtonTapped)
            } label: {
                Text("AI 테스트 통화 시작")
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("홈")
    }
}

#Preview {
    NavigationStack {
        HomeView(
            store: Store(initialState: HomeFeature.State()) {
                HomeFeature()
            }
        )
    }
}
