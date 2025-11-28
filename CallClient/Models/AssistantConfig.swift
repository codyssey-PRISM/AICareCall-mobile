//
//  AssistantConfig.swift
//  CallClient
//
//  Created by Claude Code on 11/25/25.
//

import Foundation

// MARK: - Assistant Config Response

struct AssistantConfigResponse: Codable, Equatable {
    let voice: VoiceConfig
    let model: ModelConfig
    let transcriber: TranscriberConfig
    let firstMessageMode: String
    let endCallFunctionEnabled: Bool
    let endCallMessage: String
    let serverMessages: [String]
    let maxDurationSeconds: Int
    let analysisPlan: AnalysisPlan
    let server: ServerConfig
    
    /// Convert the response to a dictionary for Vapi SDK
    func toDictionary() -> [String: Any] {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            
            guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Failed to convert AssistantConfig to dictionary")
                return [:]
            }
            
            return dictionary
        } catch {
            print("❌ Error converting AssistantConfig to dictionary: \(error)")
            return [:]
        }
    }
}

// MARK: - Voice Config

struct VoiceConfig: Codable, Equatable {
    let provider: String
    let voiceId: String
    let model: String
}

// MARK: - Model Config

struct ModelConfig: Codable, Equatable {
    let provider: String
    let model: String
    let messages: [ModelMessage]
}

struct ModelMessage: Codable, Equatable {
    let role: String
    let content: String
}

// MARK: - Transcriber Config

struct TranscriberConfig: Codable, Equatable {
    let model: String
    let language: String
    let provider: String
}

// MARK: - Analysis Plan

struct AnalysisPlan: Codable, Equatable {
    let minMessagesThreshold: Int
    let summaryPlan: SummaryPlan
    let structuredDataPlan: StructuredDataPlan
}

struct SummaryPlan: Codable, Equatable {
    let messages: [ModelMessage]
}

struct StructuredDataPlan: Codable, Equatable {
    let enabled: Bool
    let messages: [ModelMessage]
    let schema: StructuredDataSchema
    let timeoutSeconds: Int
}

struct StructuredDataSchema: Codable, Equatable {
    let type: String
    let required: [String]
    let properties: SchemaProperties
}

struct SchemaProperties: Codable, Equatable {
    let emotion: EmotionProperty
    let tags: TagsProperty
}

struct EmotionProperty: Codable, Equatable {
    let type: String
    let `enum`: [String]
}

struct TagsProperty: Codable, Equatable {
    let type: String
    let items: ItemsType
    let minItems: Int
    let maxItems: Int
}

struct ItemsType: Codable, Equatable {
    let type: String
}

// MARK: - Server Config

struct ServerConfig: Codable, Equatable {
    let url: String
}

