//
//  CallKitClient.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import Foundation

// MARK: - CallKitClient Dependency

@DependencyClient
struct CallKitClient {
    var reportIncomingCall: @Sendable (UUID, String) async throws -> Void
    var startOutgoingCall: @Sendable (UUID, String) -> Void
    var endCall: @Sendable (UUID) -> Void
    var eventStream: @Sendable () -> AsyncStream<CallKitEvent> = { AsyncStream<CallKitEvent> { _ in } }
}

// MARK: - CallKitEvent

enum CallKitEvent: Equatable {
    case callAnswered(uuid: UUID)
    case callEnded(uuid: UUID)
    case audioSessionActivated
    case audioSessionDeactivated
}

// MARK: - Dependency Values

extension CallKitClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var callKitClient: CallKitClient {
        get { self[CallKitClient.self] }
        set { self[CallKitClient.self] = newValue }
    }
}
