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
    var saveElderId: @Sendable (Int) async -> Void
    var getElderId: @Sendable () async -> Int?
}

// MARK: - Dependency Values

extension AuthStateClient: DependencyKey {
    static let liveValue: AuthStateClient = {
        let authKey = "invite_code_verified"
        let elderIdKey = "elder_id"
        
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
                UserDefaults.standard.removeObject(forKey: elderIdKey)
                print("🗑️ 초대 코드 인증 상태 삭제됨")
            },
            saveElderId: { elderId in
                UserDefaults.standard.set(elderId, forKey: elderIdKey)
                print("💾 Elder ID 저장됨:", elderId)
            },
            getElderId: {
                let elderId = UserDefaults.standard.integer(forKey: elderIdKey)
                return elderId == 0 ? nil : elderId
            }
        )
    }()
}

extension AuthStateClient: TestDependencyKey {
    static let testValue = AuthStateClient(
        saveAuthState: { _ in },
        getAuthState: { nil },
        clearAuthState: { },
        saveElderId: { _ in },
        getElderId: { nil }
    )
}

extension DependencyValues {
    var authStateClient: AuthStateClient {
        get { self[AuthStateClient.self] }
        set { self[AuthStateClient.self] = newValue }
    }
}

