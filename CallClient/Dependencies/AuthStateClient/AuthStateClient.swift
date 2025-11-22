//
//  AuthStateClient.swift
//  CallClient
//
//  Created by Claude Code on 11/22/25.
//

import ComposableArchitecture
import Foundation

// MARK: - AuthStateClient Dependency

@DependencyClient
struct AuthStateClient {
    var saveAuthState: @Sendable (String) async -> Void
    var getAuthState: @Sendable () async -> String?
    var clearAuthState: @Sendable () async -> Void
}

// MARK: - Dependency Values

extension AuthStateClient: DependencyKey {
    static let liveValue: AuthStateClient = {
        let authKey = "invite_code_verified"
        
        return AuthStateClient(
            saveAuthState: { inviteCode in
                UserDefaults.standard.set(inviteCode, forKey: authKey)
                print("💾 초대 코드 인증 상태 저장됨:", inviteCode)
            },
            getAuthState: {
                return UserDefaults.standard.string(forKey: authKey)
            },
            clearAuthState: {
                UserDefaults.standard.removeObject(forKey: authKey)
                print("🗑️ 초대 코드 인증 상태 삭제됨")
            }
        )
    }()
}

extension AuthStateClient: TestDependencyKey {
    static let testValue = AuthStateClient(
        saveAuthState: { _ in },
        getAuthState: { nil },
        clearAuthState: { }
    )
}

extension DependencyValues {
    var authStateClient: AuthStateClient {
        get { self[AuthStateClient.self] }
        set { self[AuthStateClient.self] = newValue }
    }
}

