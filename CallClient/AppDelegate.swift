//
//  AppDelegate.swift
//  CallClient
//
//  Created by seungwooKim on 11/8/25.
//

import UIKit
import PushKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, PKPushRegistryDelegate {
    
    var pushRegistry: PKPushRegistry?
    // CallKit용에서 쓸 UUID
    var currentCallUUID: UUID?
    
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
        
        // 여기서 FastAPI 서버에 토큰 보내서 저장
        // e.g. POST /register-voip-device { voip_token: tokenString }
    }
    
    func pushRegistry(_ registry: PKPushRegistry,
                      didInvalidatePushTokenFor type: PKPushType) {
        print("VoIP token invalidated for type:", type.rawValue)
        // 필요하면 서버에 삭제 요청
    }
    
    // AppDelegate 안에 추가
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
        self.currentCallUUID = uuid

        CallKitManager.shared.reportIncomingCall(uuid: uuid) { error in
            if let error = error {
                print("reportIncomingCall error:", error)
            } else {
                print("Incoming call reported via CallKit")
            }
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

