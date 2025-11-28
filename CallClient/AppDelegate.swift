//
//  AppDelegate.swift
//  CallClient
//
//  Created by seungwooKim on 11/8/25.
//

import ComposableArchitecture
import UIKit
import PushKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, PKPushRegistryDelegate {

    @Dependency(\.voipTokenClient) var voipTokenClient
    
    var pushRegistry: PKPushRegistry?
    var rootStore: StoreOf<RootFeature>?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Notification Center delegate 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("🔔 Notification permission granted? \(granted), error: \(String(describing: error))")
            
            guard granted else {
                print("⚠️ User denied notification permissions")
                return
            }
            
            // 권한이 허용되면 APNs 등록
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        setupVoIPPush()
        
        return true
    }
    
    // ✅ VoIP 토큰 수신
    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {
        guard type == .voIP else { return }
        
        let tokenData = pushCredentials.token
        let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
        print("📞 VoIP token:", tokenString)
        
        // VoIPTokenClient를 통해 토큰 저장
        Task {
            await voipTokenClient.saveToken(tokenString)
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry,
                      didInvalidatePushTokenFor type: PKPushType) {
        print("VoIP token invalidated for type:", type.rawValue)
        // 필요하면 서버에 삭제 요청
    }
    
    // VoIP 푸시 수신 시
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        guard type == .voIP else {
            completion()
            return
        }

        print("📬 Received VoIP push:", payload.dictionaryPayload)

        let uuid = UUID()

        // ⚠️ 중요: VoIP 푸시를 받으면 즉시 CallKit 호출해야 함 (Apple 정책)
        // TCA 의존성을 거치지 않고 직접 CallKitManager.shared를 호출하여
        // 앱이 백그라운드/종료 상태에서도 즉시 CallKit UI가 표시되도록 함
        
        // 1️⃣ 즉시 CallKit에 통화 보고 - 동기 호출로 지연 최소화
        CallKitManager.shared.reportIncomingCall(
            uuid: uuid,
            callerName: "Sori(소리) AI"
        ) { [weak self] error in
            if let error = error {
                print("❌ [AppDelegate] reportIncomingCall error:", error)
                completion()
                return
            }
            
            print("✅ [AppDelegate] Incoming call reported successfully")
            
            // 2️⃣ CallKit 호출 성공 후 TCA Store에 이벤트 전달 (비동기로 나중에)
            DispatchQueue.main.async {
                self?.rootStore?.send(.voipPushReceived(callUUID: uuid))
            }
            
            // 3️⃣ completion 호출 (Apple에 처리 완료 알림)
            completion()
        }
    }
    
    private func setupVoIPPush() {
        let registry = PKPushRegistry(queue: DispatchQueue.main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.pushRegistry = registry
    }
    
    // APNs 등록 성공 시
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("📱 APNs Device Token:")
        print(tokenString)
        print("✅ Copy this token to your server's DEVICE_TOKEN")
        
        // TODO: 서버로 토큰 전송하는 코드 추가 가능
        // 예: sendTokenToServer(tokenString)
    }
    
    // APNs 등록 실패 시
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications:")
        print(error.localizedDescription)
    }
    
    // 포어그라운드에서도 알림 보이도록
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📬 Notification received in foreground:")
        print("Title: \(notification.request.content.title)")
        print("Body: \(notification.request.content.body)")
        print("UserInfo: \(notification.request.content.userInfo)")
        
        // iOS 14+ 에서는 .banner, .list 사용
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    // 알림을 탭했을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 User tapped notification:")
        print("ActionIdentifier: \(response.actionIdentifier)")
        print("UserInfo: \(response.notification.request.content.userInfo)")
        
        // TODO: 알림 탭 시 특정 화면으로 이동하는 로직 추가 가능
        
        completionHandler()
    }
}

