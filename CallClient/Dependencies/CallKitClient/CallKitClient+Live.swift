//
//  CallKitClient+Live.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import AVFoundation
import CallKit
import ComposableArchitecture
import Foundation

extension CallKitClient: DependencyKey {
    static let liveValue: CallKitClient = {
        class CallKitManager: NSObject, CXProviderDelegate {
            private let provider: CXProvider
            private let callController = CXCallController()
            private var continuation: AsyncStream<CallKitEvent>.Continuation?

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

            func setContinuation(_ continuation: AsyncStream<CallKitEvent>.Continuation) {
                self.continuation = continuation
            }

            func reportIncomingCall(uuid: UUID, handle: String) async throws {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let update = CXCallUpdate()
                    update.hasVideo = false
                    update.localizedCallerName = handle

                    provider.reportNewIncomingCall(with: uuid, update: update) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }

            func startOutgoingCall(uuid: UUID, handle: String) {
                let cxHandle = CXHandle(type: .generic, value: handle)
                let startCallAction = CXStartCallAction(call: uuid, handle: cxHandle)
                startCallAction.isVideo = false

                let transaction = CXTransaction(action: startCallAction)

                callController.request(transaction) { error in
                    if let error = error {
                        print("❌ Error starting outgoing call:", error)
                    } else {
                        print("✅ Outgoing call started:", uuid)
                    }
                }
            }

            func endCall(uuid: UUID) {
                let endCallAction = CXEndCallAction(call: uuid)
                let transaction = CXTransaction(action: endCallAction)

                callController.request(transaction) { error in
                    if let error = error {
                        print("❌ Error ending call:", error)
                    } else {
                        print("✅ Call ended via CallKit:", uuid)
                    }
                }
            }

            // MARK: - CXProviderDelegate

            func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
                print("📞 Call answered:", action.callUUID)

                configureAudioSession()

                sendEvent(.callAnswered(uuid: action.callUUID))

                action.fulfill()
            }

            func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
                print("📞 Outgoing call started:", action.callUUID)

                configureAudioSession()

                let update = CXCallUpdate()
                update.hasVideo = false
                update.localizedCallerName = "AI Assistant"
                provider.reportCall(with: action.callUUID, updated: update)

                sendEvent(.callAnswered(uuid: action.callUUID))

                action.fulfill()
            }

            func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
                print("📞 Call ended:", action.callUUID)

                sendEvent(.callEnded(uuid: action.callUUID))

                action.fulfill()
            }

            func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
                print("🔊 Audio session activated")

                sendEvent(.audioSessionActivated)
            }

            func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
                print("🔇 Audio session deactivated")

                sendEvent(.audioSessionDeactivated)
            }

            func providerDidReset(_ provider: CXProvider) {
                print("⚠️ Provider reset")
            }

            // MARK: - Helper Methods

            private func sendEvent(_ event: CallKitEvent) {
                continuation?.yield(event)
            }

            private func configureAudioSession() {
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.playAndRecord, options: [.allowBluetooth, .defaultToSpeaker])
                    try audioSession.setMode(.voiceChat)
                    try audioSession.setActive(true)
                    print("✅ Audio session configured")
                } catch {
                    print("❌ Failed to configure audio session:", error)
                }
            }
        }

        let manager = CallKitManager()

        return Self(
            reportIncomingCall: { uuid, handle in
                try await manager.reportIncomingCall(uuid: uuid, handle: handle)
            },
            startOutgoingCall: { uuid, handle in
                manager.startOutgoingCall(uuid: uuid, handle: handle)
            },
            endCall: { uuid in
                manager.endCall(uuid: uuid)
            },
            eventStream: {
                AsyncStream { continuation in
                    manager.setContinuation(continuation)
                }
            }
        )
    }()
}
