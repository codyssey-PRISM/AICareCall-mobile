//
//  InvitationFeature.swift
//  CallClient
//
//  Created by Claude Code on 11/22/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct InvitationFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var code: [String] = Array(repeating: "", count: 6)
        var focusedIndex: Int? = 0
        var errorMessage: String? = nil
        var isLoading: Bool = false
        var showSuccessAlert: Bool = false
        
        var isCodeComplete: Bool {
            code.allSatisfy { !$0.isEmpty }
        }
        
        var codeString: String {
            code.joined()
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case onAppear
        case codeChanged(index: Int, value: String)
        case backspacePressed(index: Int)
        case confirmButtonTapped
        case resendCodeButtonTapped
        case verifyCodeResponse(Result<VerifyCodeResponse, Error>)
        case successAlertConfirmTapped
        case debugClearAuthState
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case completed
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.voipTokenClient) var voipTokenClient
    @Dependency(\.authStateClient) var authStateClient
    
    // MARK: - Body
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .onAppear:
                // 첫 번째 입력 칸에 포커스
                state.focusedIndex = 0
                return .none
                
            case let .codeChanged(index, value):
                // 에러 메시지 초기화
                state.errorMessage = nil
                
                let previousValue = state.code[index]
                
                // 입력값 검증 (영문/숫자만 허용, 1글자만)
                let filtered = value.filter { $0.isLetter || $0.isNumber }
                let newValue = String(filtered.prefix(1))
                
                state.code[index] = newValue
                
                // 값이 입력되면 다음 칸으로 포커스 이동
                if !newValue.isEmpty && previousValue.isEmpty && index < 5 {
                    state.focusedIndex = index + 1
                }
                // 값이 지워지면 (백스페이스) 이전 칸으로 포커스 이동
                else if newValue.isEmpty && !previousValue.isEmpty && index > 0 {
                    state.focusedIndex = index - 1
                }
                
                return .none
            
            case let .backspacePressed(index):
                // 현재 칸이 비어있고 이전 칸이 있으면
                if state.code[index].isEmpty && index > 0 {
                    // 이전 칸의 값을 삭제하고 포커스 이동
                    state.code[index - 1] = ""
                    state.focusedIndex = index - 1
                }
                // 현재 칸에 값이 있으면 그냥 삭제 (기본 TextField 동작)
                
                return .none
                
            case .confirmButtonTapped:
                guard state.isCodeComplete else { return .none }
                
                state.isLoading = true
                state.errorMessage = nil
                
                let inviteCode = state.codeString
                
                return .run { send in
                    // VoIP 토큰 가져오기
                    let deviceToken = await voipTokenClient.getToken() ?? "mock_device_token"
                    
                    // API 호출
                    let result = await apiClient.verifyInviteCode(inviteCode, deviceToken)
                    await send(.verifyCodeResponse(result))
                }
                
            case .resendCodeButtonTapped:
                // TODO: 초대 코드 재발송 로직 (추후 구현)
                print("📧 코드 재발송 요청")
                return .none
                
            case .verifyCodeResponse(.success(let response)):
                state.isLoading = false
                state.errorMessage = nil
                
                let inviteCode = state.codeString
                
                // 인증 성공 시 AuthStateClient에 저장하고 Alert 표시
                state.showSuccessAlert = true
                
                return .run { _ in
                    await authStateClient.saveAuthState(inviteCode)
                    // elder_id 저장
                    if let elderId = response.elder_id {
                        await authStateClient.saveElderId(elderId)
                        print("✅ Elder ID \(elderId) 저장 완료")
                    }
                }
                
            case .successAlertConfirmTapped:
                // Alert 확인 버튼 클릭 시 홈 화면으로 전환
                state.showSuccessAlert = false
                return .send(.delegate(.completed))
                
            case .verifyCodeResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "잘못된 코드입니다. 다시 시도해 주세요."
                
                // 코드 초기화
                state.code = Array(repeating: "", count: 6)
                state.focusedIndex = 0
                
                print("❌ 초대 코드 검증 실패:", error)
                return .none
                
            case .debugClearAuthState:
                // 디버그용: 인증 상태 삭제
                return .run { _ in
                    await authStateClient.clearAuthState()
                }
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - API Response Model

struct VerifyCodeResponse: Codable, Equatable {
    let success: Bool
    let message: String?
    let elder_id: Int?
    let elder_name: String?
}

