//
//  InvitationView.swift
//  CallClient
//
//  Created by Claude Code on 11/22/25.
//

import ComposableArchitecture
import SwiftUI

struct InvitationView: View {
    let store: StoreOf<InvitationFeature>
    @FocusState private var focusedField: Int?
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            // 배경색
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 타이틀
                HStack(spacing: 8) {
                    Image("sori_ai_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text("Sori AI")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // 중앙 컨텐츠
                VStack(spacing: 40) {
                    // 환영 메시지
                    VStack(spacing: 12) {
                        Text("초대 코드를 입력해주세요")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text("받으신 6자리 코드를 입력하여 시작하세요.")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 6자리 입력 박스
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            CodeInputField(
                                text: Binding(
                                    get: { store.code[index] },
                                    set: { newValue in
                                        store.send(.codeChanged(index: index, value: newValue))
                                    }
                                ),
                                isFocused: focusedField == index,
                                hasError: store.errorMessage != nil,
                                onBackspace: {
                                    store.send(.backspacePressed(index: index))
                                }
                            )
                            .focused($focusedField, equals: index)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 에러 메시지
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                // 하단 버튼
                VStack(spacing: 16) {
                    Button {
                        store.send(.resendCodeButtonTapped)
                    } label: {
                        Text("코드를 받지 못하셨나요?")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    
                    Button {
                        store.send(.confirmButtonTapped)
                    } label: {
                        ZStack {
                            Text("확인")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(store.isLoading ? 0 : 1)
                            
                            if store.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            store.isCodeComplete && !store.isLoading
                                ? Color.blue
                                : Color.blue.opacity(0.5)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!store.isCodeComplete || store.isLoading)
                    
                    #if DEBUG
                    // 디버그 버튼: 인증 상태 삭제
                    Button {
                        store.send(.debugClearAuthState)
                    } label: {
                        Text("🔧 DEBUG: 인증 상태 삭제")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            store.send(.onAppear)
            // 화면 진입 시 첫 번째 칸에 포커스
            if !hasAppeared {
                hasAppeared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = 0
                }
            }
        }
        .onChange(of: store.focusedIndex) { _, newValue in
            focusedField = newValue
        }
        .alert("인증 완료", isPresented: Binding(
            get: { store.showSuccessAlert },
            set: { _ in }
        )) {
            Button("확인") {
                store.send(.successAlertConfirmTapped)
            }
        } message: {
            Text("초대 코드 인증이 완료되었습니다.")
        }
        .interactiveDismissDisabled(store.showSuccessAlert)
    }
}

// MARK: - Code Input Field

struct CodeInputField: View {
    @Binding var text: String
    let isFocused: Bool
    let hasError: Bool
    let onBackspace: () -> Void
    
    var body: some View {
        BackspaceDetectingTextField(
            text: $text,
            onBackspace: onBackspace
        )
        .font(.system(size: 32, weight: .semibold))
        .multilineTextAlignment(.center)
        .keyboardType(.asciiCapable)
        .autocapitalization(.allCharacters)
        .disableAutocorrection(true)
        .frame(width: 48, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    hasError ? Color.red :
                    isFocused ? Color.blue :
                    Color.clear,
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Backspace Detecting TextField

struct BackspaceDetectingTextField: UIViewRepresentable {
    @Binding var text: String
    let onBackspace: () -> Void
    
    func makeUIView(context: Context) -> BackspaceTextField {
        let textField = BackspaceTextField()
        textField.delegate = context.coordinator
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 32, weight: .semibold)
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.onBackspace = onBackspace
        return textField
    }
    
    func updateUIView(_ uiView: BackspaceTextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
            text = newText
            return true
        }
    }
}

class BackspaceTextField: UITextField {
    var onBackspace: (() -> Void)?
    
    override func deleteBackward() {
        let wasEmpty = text?.isEmpty ?? true
        super.deleteBackward()
        
        // 텍스트가 이미 비어있었으면 onBackspace 호출
        if wasEmpty {
            onBackspace?()
        }
    }
}

// MARK: - Preview

#Preview {
    InvitationView(
        store: Store(initialState: InvitationFeature.State()) {
            InvitationFeature()
        }
    )
}

