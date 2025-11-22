//
//  RootFeature.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct RootFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var destination: Destination.State = .splash(SplashFeature.State())
        var pendingCallUUID: UUID? = nil
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case destination(Destination.Action)

        // VoIP/CallKit 이벤트
        case voipPushReceived(callUUID: UUID)
        case callKitEvent(CallKitEvent)
        case callKitAnswered(callUUID: UUID)
        case callKitEnded(callUUID: UUID)
    }

    // MARK: - Dependencies

    @Dependency(\.callKitClient) var callKitClient

    // MARK: - Destination Reducer (최신 TCA 패턴)

    @Reducer(state: .equatable)
    enum Destination {
        case splash(SplashFeature)
        case home(HomeFeature)
        case call(CallFeature)
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Scope(state: \.destination, action: \.destination) {
            Destination.body
        }
        
        Reduce { state, action in
            switch action {

            // MARK: - Lifecycle

            case .onAppear:
                // CallKit 이벤트 스트림 구독
                return .run { send in
                    for await event in callKitClient.eventStream() {
                        await send(.callKitEvent(event))
                    }
                }

            // MARK: - Destination Actions

            case .destination(.splash(.delegate(.completed))):
                // Splash 완료 → pending call이 있으면 Call로, 없으면 Home으로
                if let pendingUUID = state.pendingCallUUID {
                    state.destination = .call(CallFeature.State(callUUID: pendingUUID))
                    state.pendingCallUUID = nil
                } else {
                    state.destination = .home(HomeFeature.State())
                }
                return .none

            case .destination(.home(.delegate(.startCall(let uuid)))):
                // Home에서 통화 시작 → Call 화면으로 전환
                state.destination = .call(CallFeature.State(callUUID: uuid))
                return .none

            case .destination(.call(.delegate(.callEnded))):
                // 통화 종료 → Home으로 복귀
                state.destination = .home(HomeFeature.State())
                return .none

            case .destination:
                return .none

            // MARK: - VoIP/CallKit Events

            case .voipPushReceived(let callUUID):
                // VoIP 푸시 수신 → pending call로 저장
                // CallKit이 answer 이벤트를 발생시킬 때까지 대기
                print("📬 VoIP push received for call: \(callUUID)")
                state.pendingCallUUID = callUUID
                return .none

            case .callKitEvent(let event):
                // CallKit 이벤트 처리
                switch event {
                case .callAnswered(let uuid):
                    return .send(.callKitAnswered(callUUID: uuid))

                case .callEnded(let uuid):
                    return .send(.callKitEnded(callUUID: uuid))

                case .audioSessionActivated:
                    print("🔊 Audio session activated")
                    return .none

                case .audioSessionDeactivated:
                    print("🔇 Audio session deactivated")
                    return .none
                }

            case .callKitAnswered(let callUUID):
                // CallKit에서 전화 수락
                print("📞 CallKit answered: \(callUUID)")
                
                // 현재 Splash 화면이면 pending으로 저장 (Splash 완료 후 자동 전환)
                // 이미 Home이나 다른 화면이면 즉시 전환
                switch state.destination {
                case .splash:
                    state.pendingCallUUID = callUUID
                default:
                    state.destination = .call(CallFeature.State(callUUID: callUUID))
                }
                return .none

            case .callKitEnded(let callUUID):
                // CallKit에서 전화 종료
                print("📞 CallKit ended: \(callUUID)")
                
                // pending call 취소
                if state.pendingCallUUID == callUUID {
                    state.pendingCallUUID = nil
                }
                
                // Call 화면에 있었다면 Home으로 복귀
                if case .call = state.destination {
                    state.destination = .home(HomeFeature.State())
                }
                return .none
            }
        }
    }
}
