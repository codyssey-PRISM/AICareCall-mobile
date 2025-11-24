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
        ZStack {
            // 배경색
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 타이틀
                HStack(spacing: 8) {
                    Image("sori_ai_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text("소리(Sori) AI")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // 중앙 컨텐츠
                VStack(spacing: 32) {
                    Text("안부 전화를 시작하려면\n아래 버튼을 눌러주세요.")
                        .font(.system(size: 17))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                    
                    // 동그란 파란색 전화 버튼
                    Button {
                        store.send(.startCallButtonTapped)
                    } label: {
                        VStack(spacing: 16) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("전화 걸기")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 200, height: 200)
                        .background(
                            Circle()
                                .fill(Color.blue)
                                .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                    }
                }
                
                Spacer()
                
                // 하단 안내 텍스트
                Text("AI가 전화로 안부를 묻습니다")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
            }
        }
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
