//
//  APIClient.swift
//  CallClient
//
//  Created by Claude Code on 11/22/25.
//

import ComposableArchitecture
import Foundation

// MARK: - APIClient Dependency

@DependencyClient
struct APIClient {
    var verifyInviteCode: @Sendable (String, String) async -> Result<VerifyCodeResponse, Error> = { _, _ in
            .success(VerifyCodeResponse(success: true,
                                        message: "success", elder_id: 1, elder_name: "Test Elder"))
    }
    var getAssistantConfig: @Sendable (Int) async -> Result<AssistantConfigResponse, Error> = { _ in
            .failure(APIError.invalidResponse)
    }
}

// MARK: - Dependency Values

extension APIClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

