//
//  VoIPTokenClient.swift
//  CallClient
//
//  Created by Claude Code on 11/22/25.
//

import ComposableArchitecture
import Foundation

// MARK: - VoIPTokenClient Dependency

@DependencyClient
struct VoIPTokenClient {
    var saveToken: @Sendable (String) async -> Void
    var getToken: @Sendable () async -> String?
}

// MARK: - Dependency Values

extension VoIPTokenClient: DependencyKey {
    static let liveValue: VoIPTokenClient = {
        let tokenKey = "voip_device_token"
        
        return VoIPTokenClient(
            saveToken: { token in
                UserDefaults.standard.set(token, forKey: tokenKey)
                print("💾 VoIP 토큰 저장됨:", token)
            },
            getToken: {
                return UserDefaults.standard.string(forKey: tokenKey)
            }
        )
    }()
}

extension VoIPTokenClient: TestDependencyKey {
    static let testValue = VoIPTokenClient(
        saveToken: { _ in },
        getToken: { nil }
    )
}

extension DependencyValues {
    var voipTokenClient: VoIPTokenClient {
        get { self[VoIPTokenClient.self] }
        set { self[VoIPTokenClient.self] = newValue }
    }
}

