//
//  CallFeature.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CallFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        enum CallState: Equatable {
            case loading
            case started
            case ending
            case ended
        }

        var callUUID: UUID
        var callState: CallState = .loading
        var isMuted: Bool = false
        var lastEventDescription: String = ""
        var callDuration: TimeInterval = 0
        var showingEndCallAlert: Bool = false
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case muteToggled
        case endCallButtonTapped
        case confirmEndCall
        case cancelEndCall
        case timerTick

        // Vapi 이벤트
        case vapiEvent(VapiEvent)
        case vapiCallStarted
        case vapiCallEnded
        case vapiError(Error)

        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case callEnded
        }
    }

    // MARK: - Dependencies

    @Dependency(\.vapiClient) var vapiClient
    @Dependency(\.callKitClient) var callKitClient
    @Dependency(\.continuousClock) var clock
    
    private enum CancelID { 
        case timer
        case vapiStream
        case endingDelay
    }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                // 통화 시작
                return .run { send in
                    // Vapi 통화 시작
                    do {
                        try await vapiClient.start()
                    } catch {
                        await send(.vapiError(error))
                        return
                    }

                    // Vapi 이벤트 스트림 구독
                    for await event in vapiClient.eventStream() {
                        await send(.vapiEvent(event))
                    }
                }
                .cancellable(id: CancelID.vapiStream)

            case .muteToggled:
                let newMuted = !state.isMuted
                state.isMuted = newMuted

                return .run { send in
                    do {
                        try await vapiClient.setMuted(newMuted)
                    } catch {
                        print("❌ Mute toggle failed:", error)
                        // 실패시 원래 상태로 되돌림
                        await send(.muteToggled)
                    }
                }

            case .endCallButtonTapped:
                // Alert 표시
                state.showingEndCallAlert = true
                return .none

            case .cancelEndCall:
                state.showingEndCallAlert = false
                return .none

            case .confirmEndCall:
                state.showingEndCallAlert = false
                state.callState = .ending
                
                // Vapi 통화 종료
                vapiClient.stop()
                
                // 모든 진행 중인 effect 취소 후 3초 대기 후 종료
                return .concatenate(
                    .cancel(id: CancelID.timer),
                    .cancel(id: CancelID.vapiStream),
                    .run { [uuid = state.callUUID] send in
                        try await clock.sleep(for: .seconds(3))
                        await callKitClient.endCall(uuid)
                        await send(.delegate(.callEnded))
                    }
                    .cancellable(id: CancelID.endingDelay)
                )

            // MARK: - Vapi Events

            case .vapiEvent(let event):
                state.lastEventDescription = String(describing: event)

                switch event {
                case .callDidStart:
                    return .send(.vapiCallStarted)

                case .callDidEnd:
                    return .send(.vapiCallEnded)

                case .error(let error):
                    return .send(.vapiError(error))

                default:
                    print("Vapi event:", event)
                    return .none
                }

            case .vapiCallStarted:
                state.callState = .started
                state.callDuration = 0
                
                // 1초마다 타이머 업데이트
                return .run { send in
                    while true {
                        try await clock.sleep(for: .seconds(1))
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)

            case .vapiCallEnded:
                // 이미 종료 중이면 무시 (confirmEndCall에서 처리)
                guard state.callState != .ending else { return .none }
                
                state.callState = .ended
                
                // 모든 진행 중인 effect 취소
                return .concatenate(
                    .cancel(id: CancelID.timer),
                    .cancel(id: CancelID.vapiStream),
                    .send(.delegate(.callEnded))
                )

            case .vapiError(let error):
                print("❌ Vapi error:", error)
                state.callState = .ended
                state.lastEventDescription = "Error: \(error.localizedDescription)"
                
                // 모든 진행 중인 effect 취소
                return .concatenate(
                    .cancel(id: CancelID.timer),
                    .cancel(id: CancelID.vapiStream),
                    .cancel(id: CancelID.endingDelay),
                    .send(.delegate(.callEnded))
                )

            case .timerTick:
                state.callDuration += 1
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - VapiEvent

enum VapiEvent: Equatable {
    case callDidStart
    case callDidEnd
    case speechUpdate
    case conversationUpdate
    case functionCall
    case hang
    case metadata
    case transcript
    case statusUpdate
    case modelOutput
    case userInterrupted
    case voiceInput
    case error(VapiError)
}

struct VapiError: Error, Equatable {
    let message: String
}
