//
//  VapiClient.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import ComposableArchitecture
import Foundation

// MARK: - VapiClient Dependency

@DependencyClient
struct VapiClient {
    var start: @Sendable () async throws -> Void
    var stop: @Sendable () -> Void
    var setMuted: @Sendable (Bool) async throws -> Void
    var eventStream: @Sendable () -> AsyncStream<VapiEvent> = { AsyncStream { _ in } }
}

// MARK: - Dependency Values

extension VapiClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var vapiClient: VapiClient {
        get { self[VapiClient.self] }
        set { self[VapiClient.self] = newValue }
    }
}
