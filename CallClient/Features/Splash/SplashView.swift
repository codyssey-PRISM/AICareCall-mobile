//
//  SplashView.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import SwiftUI

struct SplashView: View {
    let store: StoreOf<SplashFeature>

    var body: some View {
        ZStack {
            // 배경색
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 로고나 아이콘 (현재는 SF Symbol 사용)
                Image("sori_ai_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                // 앱 이름
                Text("소리(Sori)AI")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.primary)

                // 서브타이틀
                Text("AI가 전화로 안부를 묻습니다")
                    .font(.body)
                    .foregroundColor(.secondary)

                // 로딩 인디케이터
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

#Preview {
    SplashView(
        store: Store(initialState: SplashFeature.State()) {
            SplashFeature()
        }
    )
}
