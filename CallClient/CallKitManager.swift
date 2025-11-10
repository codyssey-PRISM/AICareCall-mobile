//
//  CallKitManager.swift
//  CallClient
//
//  Created by seungwooKim on 11/10/25.
//

import Foundation
import CallKit
import AVFoundation

final class CallKitManager: NSObject, CXProviderDelegate {
    
    static let shared = CallKitManager()

    private let provider: CXProvider
    private let callController = CXCallController()

    override init() {
        let config = CXProviderConfiguration(localizedName: "AI Call")
        config.supportsVideo = false
        config.includesCallsInRecents = true
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.generic]

        provider = CXProvider(configuration: config)

        super.init()
        provider.setDelegate(self, queue: nil)
    }

    // ✅ 새 수신 전화 보고 (VoIP 푸시 들어왔을 때 호출)
    func reportIncomingCall(uuid: UUID, handle: String = "AI Assistant", completion: @escaping (Error?) -> Void) {
        let update = CXCallUpdate()
        update.hasVideo = false
        update.localizedCallerName = handle

        provider.reportNewIncomingCall(with: uuid, update: update, completion: completion)
    }

    // ✅ 유저가 통화 수락했을 때
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("📞 Call answered:", action.callUUID)
        // 여기에서 앱 쪽에 "통화 시작" 이벤트를 보내고 Vapi 콜 시작
        NotificationCenter.default.post(name: .callKitDidAnswer, object: action.callUUID)
        action.fulfill()
    }

    // ✅ 유저가 통화 종료했을 때
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("📞 Call ended:", action.callUUID)
        NotificationCenter.default.post(name: .callKitDidEnd, object: action.callUUID)
        action.fulfill()
    }

    func providerDidReset(_ provider: CXProvider) {
        
    }
}

extension Notification.Name {
    static let callKitDidAnswer = Notification.Name("callKitDidAnswer")
    static let callKitDidEnd = Notification.Name("callKitDidEnd")
}
