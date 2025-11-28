//
//  CallKitClient+Live.swift
//  CallClient
//
//  Created by Claude Code on 11/26/25.
//

import AVFoundation
import CallKit
import ComposableArchitecture
import Foundation

// MARK: - CallKit Error

enum CallKitError: Error {
    case timeout
}

// MARK: - Live Implementation

extension CallKitClient: DependencyKey {
    static let liveValue: CallKitClient = {
        let manager = CallKitManager.shared
        
        return Self(
            reportIncomingCall: { uuid, callerName in
                try await manager.reportIncomingCall(uuid: uuid, callerName: callerName)
            },
            reportIncomingCallImmediately: { uuid, callerName, completion in
                manager.reportIncomingCall(
                    uuid: uuid,
                    callerName: callerName,
                    completion: completion
                )
            },
            startOutgoingCall: { uuid, handle in
                await manager.startOutgoingCall(uuid: uuid, handle: handle)
            },
            endCall: { uuid in
                await manager.endCall(uuid: uuid)
            },
            eventStream: {
                manager.eventStream()
            }
        )
    }()
}
