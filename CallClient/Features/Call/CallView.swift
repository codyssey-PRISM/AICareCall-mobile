//
//  CallView.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import SwiftUI

struct CallView: View {
    let store: StoreOf<CallFeature>

    var body: some View {
        ZStack {
            // 배경색
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 중앙 컨텐츠
                VStack(spacing: 24) {
                    // Sori AI 아이콘
                    Image("sori_ai_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .opacity(store.callState == .loading || store.callState == .ending ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: store.callState)
                    
                    // Sori AI 타이틀
                    Text("Sori AI")
                        .font(.system(size: 32, weight: .bold))
                        .opacity(store.callState == .loading || store.callState == .ending ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: store.callState)
                    
                    // 통화 시간
                    if store.callState == .started {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text(formattedDuration)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    } else if store.callState == .loading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("연결 중...")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    } else if store.callState == .ending {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("통화를 종료하는 중입니다")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 하단 버튼
                HStack {
                    // 음소거 버튼
                    VStack(spacing: 8) {
                        Button {
                            store.send(.muteToggled)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: store.isMuted ? "mic.slash.fill" : "mic.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                
                            }
                            .frame(width: 80, height: 80)
                            .background(Circle().fill(Color.gray.opacity(0.8)))
                        }
                        .disabled(store.callState != .started)
                        .opacity(store.callState == .started ? 1.0 : 0.4)
                        
                        Text(store.isMuted ? "음소거 해제" : "음소거")
                            .font(.system(size: 14))
                            .opacity(store.callState == .started ? 1.0 : 0.4)
                    }
                    
                    Spacer()
                    
                    // 통화 종료 버튼
                    VStack(spacing: 8) {
                        Button {
                            store.send(.endCallButtonTapped)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 80, height: 80)
                            .background(Circle().fill(Color.red))
                        }
                        .disabled(store.callState == .ending)
                        .opacity(store.callState == .ending ? 0.4 : 1.0)
                        
                        Text("통화 종료")
                            .font(.system(size: 14))
                            .opacity(store.callState == .ending ? 0.4 : 1.0)
                    }
                    
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.send(.onAppear)
        }
        .alert("통화 종료",
               isPresented: .init(
                   get: { store.showingEndCallAlert },
                   set: { _ in store.send(.cancelEndCall) }
               )) {
            Button("취소", role: .cancel) {
                store.send(.cancelEndCall)
            }
            Button("확인", role: .destructive) {
                store.send(.confirmEndCall)
            }
        } message: {
            Text("통화를 종료하시겠습니까?")
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDuration: String {
        let minutes = Int(store.callDuration) / 60
        let seconds = Int(store.callDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        CallView(
            store: Store(initialState: CallFeature.State(callUUID: UUID())) {
                CallFeature()
            }
        )
    }
}
