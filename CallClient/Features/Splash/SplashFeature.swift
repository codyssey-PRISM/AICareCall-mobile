//
//  SplashFeature.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SplashFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var isTimerActive = false
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case timerFinished
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case completed
        }
    }

    // MARK: - Dependencies

    @Dependency(\.continuousClock) var clock

    // MARK: - Body

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                guard !state.isTimerActive else { return .none }
                state.isTimerActive = true

                // 2초 후 자동 전환
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.timerFinished)
                }

            case .timerFinished:
                state.isTimerActive = false
                return .send(.delegate(.completed))

            case .delegate:
                return .none
            }
        }
    }
}
