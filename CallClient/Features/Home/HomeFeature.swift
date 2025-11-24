//
//  HomeFeature.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {}

    // MARK: - Action

    enum Action {
        case startCallButtonTapped
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case startCall(uuid: UUID)
        }
    }

    // MARK: - Dependencies

    @Dependency(\.callKitClient) var callKitClient
    @Dependency(\.uuid) var uuid

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .startCallButtonTapped:
                // 새 통화 UUID 생성
                let callUUID = uuid()

                // CallKit을 통해 발신 전화 시작
                return .run { send in
                    await callKitClient.startOutgoingCall(callUUID, "AI Assistant")
                    await send(.delegate(.startCall(uuid: callUUID)))
                }

            case .delegate:
                return .none
            }
        }
    }
}
