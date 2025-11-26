//
//  CallKitManager.swift
//  CallClient
//
//  Created by Claude Code on 11/26/25.
//

import AVFoundation
import CallKit
import Foundation

// MARK: - CallKit Manager

/// CallKit 관리 싱글톤 클래스
/// AppDelegate에서 VoIP 푸시 수신 시 직접 호출하기 위해 분리
final class CallKitManager: NSObject {
    static let shared = CallKitManager()
    
    private let provider: CXProvider
    private let callController: CXCallController
    private var eventContinuation: AsyncStream<CallKitEvent>.Continuation?
    
    private override init() {
        // Provider Configuration - localizedName은 init에서 설정
        let configuration = CXProviderConfiguration()
//        configuration.localizedName = "소리AI"
        configuration.supportsVideo = false
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        
        // 벨소리 설정 (옵션)
        // configuration.ringtoneSound = "ringtone.caf"
        
        self.provider = CXProvider(configuration: configuration)
        self.callController = CXCallController()
        
        super.init()
        
        // delegate는 메인 큐에서 호출되도록 설정
        self.provider.setDelegate(self, queue: DispatchQueue.main)
    }
    
    // MARK: - Public API
    
    /// VoIP 푸시에서 즉시 호출용 (동기 버전)
    /// Apple 정책상 reportNewIncomingCall을 즉시 호출해야 하므로
    /// 콜백을 기다리지 않고 바로 호출만 함
    func reportIncomingCall(uuid: UUID, callerName: String, completion: @escaping (Error?) -> Void) {
        // 반드시 메인 스레드에서 실행되어야 함
        // dispatchPrecondition(condition: .onQueue(.main))
        
        print("📞 [CallKit] Reporting incoming call IMMEDIATELY: \(uuid)")
        
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.localizedCallerName = callerName
        update.hasVideo = false
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false
        
        // ⚠️ 즉시 provider 호출 - 이 호출 자체가 Apple에게 "시도했다"는 신호
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("❌ [CallKit] Failed to report incoming call: \(error.localizedDescription)")
                completion(error)
            } else {
                print("✅ [CallKit] Successfully reported incoming call")
                completion(nil)
            }
        }
    }
    
    /// 비동기 버전: 일반 사용 (TCA 등에서 호출)
    @MainActor
    func reportIncomingCall(uuid: UUID, callerName: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            reportIncomingCall(uuid: uuid, callerName: callerName) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    func startOutgoingCall(uuid: UUID, handle: String) async {
        print("📞 [CallKit] Starting outgoing call: \(uuid)")
        
        let handle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = false
        
        let transaction = CXTransaction(action: startCallAction)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            callController.request(transaction) { error in
                if let error = error {
                    print("❌ [CallKit] Failed to start outgoing call: \(error.localizedDescription)")
                } else {
                    print("✅ [CallKit] Successfully requested outgoing call")
                }
                continuation.resume()
            }
        }
    }
    
    @MainActor
    func endCall(uuid: UUID) async {
        print("📞 [CallKit] Ending call: \(uuid)")
        
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            callController.request(transaction) { error in
                if let error = error {
                    print("❌ [CallKit] Failed to end call: \(error.localizedDescription)")
                } else {
                    print("✅ [CallKit] Successfully ended call")
                }
                continuation.resume()
            }
        }
    }
    
    func eventStream() -> AsyncStream<CallKitEvent> {
        AsyncStream { [weak self] continuation in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.eventContinuation = continuation
            }
            
            continuation.onTermination = { @Sendable [weak self] _ in
                DispatchQueue.main.async {
                    self?.eventContinuation = nil
                }
            }
        }
    }
    
    private func sendEvent(_ event: CallKitEvent) {
        // 메인 스레드에서 호출됨 (delegate가 메인 큐에서 실행)
        eventContinuation?.yield(event)
    }
}

// MARK: - CXProviderDelegate

extension CallKitManager: CXProviderDelegate {
    
    func providerDidReset(_ provider: CXProvider) {
        print("📞 [CallKit] Provider did reset")
    }
    
    // 사용자가 전화를 수락했을 때
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("📞 [CallKit] User answered call: \(action.callUUID)")
        
        sendEvent(.callAnswered(uuid: action.callUUID))
        action.fulfill()
    }
    
    // 사용자가 전화를 종료했을 때
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("📞 [CallKit] User ended call: \(action.callUUID)")
        
        sendEvent(.callEnded(uuid: action.callUUID))
        action.fulfill()
    }
    
    // 오디오 세션 활성화
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("🔊 [CallKit] Audio session activated")
        
        sendEvent(.audioSessionActivated)
    }
    
    // 오디오 세션 비활성화
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("🔇 [CallKit] Audio session deactivated")
        
        sendEvent(.audioSessionDeactivated)
    }
}

