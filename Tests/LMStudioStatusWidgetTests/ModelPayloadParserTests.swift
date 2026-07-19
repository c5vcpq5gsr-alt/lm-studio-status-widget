import Foundation
import Testing
@testable import LMStudioStatusWidget

struct ModelPayloadParserTests {
    @Test
    func parsesCurrentLMStudioV1Payload() throws {
        let data = Data(#"{"models":[{"key":"qwen/qwen3.5-9b","displayName":"Qwen 3.5 9B","type":"llm","maxContextLength":262144,"loadedInstances":[{},{}]}]}"#.utf8)

        let model = try #require(
            ModelPayloadParser.parseModels(from: data, assumesLoadedModels: false).first
        )

        #expect(model.id == "qwen/qwen3.5-9b")
        #expect(model.name == "Qwen 3.5 9B")
        #expect(model.modelKey == "qwen/qwen3.5-9b")
        #expect(model.type == "llm")
        #expect(model.contextLength == 262_144)
        #expect(model.loadedInstances == 2)
        #expect(model.activity == .idle)
        #expect(model.queuedRequests == 0)
    }

    @Test
    func treatsOpenAIModelsEndpointEntriesAsLoaded() throws {
        let data = Data(#"{"data":[{"id":"text-embedding-qwen3-embedding-4b"}]}"#.utf8)

        let model = try #require(
            ModelPayloadParser.parseModels(from: data, assumesLoadedModels: true).first
        )

        #expect(model.id == "text-embedding-qwen3-embedding-4b")
        #expect(model.name == "text-embedding-qwen3-embedding-4b")
        #expect(model.loadedInstances == 1)
    }

    @Test
    func ignoresEntriesWithoutAnIdentifier() throws {
        let data = Data(#"{"models":[{"type":"llm"}]}"#.utf8)

        let models = try ModelPayloadParser.parseModels(from: data, assumesLoadedModels: false)

        #expect(models.isEmpty)
    }
}
