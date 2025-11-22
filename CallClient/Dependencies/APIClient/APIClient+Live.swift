//
//  APIClient+Live.swift
//  CallClient
//
//  Created by Claude Code on 11/22/25.
//

import ComposableArchitecture
import Foundation

// MARK: - Live Implementation

extension APIClient: DependencyKey {
    static let liveValue = Self(
        verifyInviteCode: { inviteCode, deviceToken in
            do {
                // TODO: 실제 서버 URL로 변경 필요
                let baseURL = "http://localhost:8000"
                let url = URL(string: "\(baseURL)/elder-app/invitation-code")!
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "invite_code": inviteCode,
                    "voip_device_token": deviceToken
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
                
                let result = try JSONDecoder().decode(VerifyCodeResponse.self, from: data)
                return .success(result)
                
            } catch {
                print("❌ API Error:", error)
                return .failure(error)
            }
        }
    )
}

// MARK: - API Error

enum APIError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
}

