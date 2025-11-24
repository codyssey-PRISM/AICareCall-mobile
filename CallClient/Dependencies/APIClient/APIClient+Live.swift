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
                // Mac 로컬 서버 주소 (실기기 테스트용)
                // localhost는 실기기에서 작동하지 않으므로 Mac의 IP 사용
                let baseURL = "http://10.19.211.245:8000"
                let url = URL(string: "\(baseURL)/elder-app/invitation-code")!
                
                print("🌐 API 요청: \(url.absoluteString)")
                print("📤 invite_code: \(inviteCode), device_token: \(deviceToken)")
                
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
                    print("❌ API 응답 에러: Invalid HTTP Response")
                    throw APIError.invalidResponse
                }
                
                print("📥 API 응답: HTTP \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ API 에러: HTTP \(httpResponse.statusCode)")
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("   에러 내용: \(errorBody)")
                    }
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
                
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("✅ API 성공 응답: \(responseBody)")
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

