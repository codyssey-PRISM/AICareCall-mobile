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
            case ended
        }

        var callUUID: UUID
        var callState: CallState = .loading
        var isMuted: Bool = false
        var lastEventDescription: String = ""
        var callDuration: TimeInterval = 0
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case muteToggled
        case endCallButtonTapped
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
    
    private enum CancelID { case timer }

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                // 통화 시작
                return .run { [uuid = state.callUUID] send in
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

            case .muteToggled:
                let newMuted = !state.isMuted
                state.isMuted = newMuted

                return .run { _ in
                    try await vapiClient.setMuted(newMuted)
                }

            case .endCallButtonTapped:
                // Vapi 통화 종료
                vapiClient.stop()

                // CallKit 통화 종료
                return .run { [uuid = state.callUUID] send in
                    await callKitClient.endCall(uuid)
                    await send(.delegate(.callEnded))
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)

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
                state.callState = .ended
                return .concatenate(
                    .cancel(id: CancelID.timer),
                    .send(.delegate(.callEnded))
                )

            case .vapiError(let error):
                print("❌ Vapi error:", error)
                state.callState = .ended
                state.lastEventDescription = "Error: \(error.localizedDescription)"
                return .concatenate(
                    .cancel(id: CancelID.timer),
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
