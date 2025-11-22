//
//  VapiClient+Live.swift
//  CallClient
//
//  Created by Claude Code on 11/21/25.
//

import AVFoundation
import ComposableArchitecture
import Combine
import Foundation
import Vapi

extension VapiClient: DependencyKey {
    static let liveValue: VapiClient = {
        let vapi = Vapi(publicKey: "ee7fb4cd-eeff-4146-963f-5292ee17a5a4")
        let assistantId = "4de84fad-6774-45cb-b865-ee77a7b2485c"

        // Vapi 이벤트를 AsyncStream으로 변환하기 위한 Continuation
        class EventStreamManager {
            var continuation: AsyncStream<VapiEvent>.Continuation?
            var cancellable: AnyCancellable?

            func setup(vapi: Vapi) -> AsyncStream<VapiEvent> {
                AsyncStream { continuation in
                    self.setContinuation(continuation)
                    self.subscribe(to: vapi)
                }
            }

            func setContinuation(_ continuation: AsyncStream<VapiEvent>.Continuation) {
                self.continuation = continuation
            }

            func subscribe(to vapi: Vapi) {
                cancellable = vapi.eventPublisher
                    .sink { [weak self] event in
                        guard let self else { return }
                        self.handleEvent(event)
                    }
            }

            func handleEvent(_ event: Vapi.Event) {
                let vapiEvent: VapiEvent

                switch event {
                case .callDidStart:
                    vapiEvent = .callDidStart
                case .callDidEnd:
                    vapiEvent = .callDidEnd
                case .speechUpdate:
                    vapiEvent = .speechUpdate
                case .conversationUpdate:
                    vapiEvent = .conversationUpdate
                case .functionCall:
                    vapiEvent = .functionCall
                case .hang:
                    vapiEvent = .hang
                case .metadata:
                    vapiEvent = .metadata
                case .transcript:
                    vapiEvent = .transcript
                case .statusUpdate:
                    vapiEvent = .statusUpdate
                case .modelOutput:
                    vapiEvent = .modelOutput
                case .userInterrupted:
                    vapiEvent = .userInterrupted
                case .voiceInput:
                    vapiEvent = .voiceInput
                case .error(let error):
                    vapiEvent = .error(VapiError(message: error.localizedDescription))
                }

                continuation?.yield(vapiEvent)
            }

            func cleanup() {
                cancellable?.cancel()
                continuation?.finish()
            }
        }

        let eventStreamManager = EventStreamManager()

        return Self(
            start: {
                // Audio Session 설정
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, options: [.allowBluetooth, .defaultToSpeaker])
                try audioSession.setMode(.voiceChat)
                try audioSession.setActive(true)
                print("✅ VapiClient: Audio session configured")

                // Vapi 통화 시작
                try await vapi.start(assistantId: assistantId)
            },
            stop: {
                vapi.stop()
            },
            setMuted: { muted in
                try await vapi.setMuted(muted)
            },
            eventStream: {
                eventStreamManager.setup(vapi: vapi)
            }
        )
    }()
}
