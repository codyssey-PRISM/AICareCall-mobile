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
        VStack(spacing: 24) {

            // 상단 상태 텍스트
            VStack(spacing: 8) {
                Text(titleText(for: store.callState))
                    .font(.title2.bold())

                Text(subtitleText(for: store.callState))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)

            // 통화 상태에 따른 간단한 인디케이터
            if store.callState == .loading {
                ProgressView("AI 통화 연결 중...")
                    .progressViewStyle(.circular)
            }

            // 디버깅/정보용 이벤트 로그
            VStack(alignment: .leading, spacing: 8) {
                Text("최근 이벤트")
                    .font(.headline)

                ScrollView {
                    Text(store.lastEventDescription.isEmpty
                         ? "아직 이벤트가 없습니다."
                         : store.lastEventDescription)
                        .font(.footnote.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
                .frame(maxHeight: 160)
            }

            Spacer()

            // 하단 버튼들
            HStack(spacing: 16) {
                // 음소거 토글
                Button {
                    store.send(.muteToggled)
                } label: {
                    VStack {
                        Image(systemName: store.isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.title2)
                        Text(store.isMuted ? "음소거 해제" : "음소거")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .cornerRadius(16)
                }

                // 통화 종료
                Button {
                    store.send(.endCallButtonTapped)
                } label: {
                    VStack {
                        Image(systemName: "phone.down.fill")
                            .font(.title2)
                        Text("통화 종료")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(16)
                }
            }

            Spacer()
                .frame(height: 16)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Computed UI Texts

    private func titleText(for state: CallFeature.State.CallState) -> String {
        switch state {
        case .loading:
            return "연결 중…"
        case .started:
            return "AI와 통화 중"
        case .ended:
            return "통화가 종료되었습니다"
        }
    }

    private func subtitleText(for state: CallFeature.State.CallState) -> String {
        switch state {
        case .loading:
            return "잠시만 기다려 주세요. AI 음성 통화를 준비 중입니다."
        case .started:
            return "자유롭게 말씀해 보세요. AI가 음성으로 응답합니다."
        case .ended:
            return "다시 통화를 시작하려면 홈 화면에서 재시도할 수 있습니다."
        }
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
