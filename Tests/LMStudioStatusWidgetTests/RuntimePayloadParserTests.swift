import Foundation
import Testing
@testable import LMStudioStatusWidget

struct RuntimePayloadParserTests {
    @Test
    func parsesGenerationAndQueueState() throws {
        let data = Data(#"[{"identifier":"qwen/qwen3.5-9b","status":"generating","queued":2}]"#.utf8)

        let info = try #require(RuntimePayloadParser.parseRuntimeInfo(from: data).first)

        #expect(info.identifier == "qwen/qwen3.5-9b")
        #expect(info.activity == .generating)
        #expect(info.queuedRequests == 2)
    }

    @Test
    func treatsUnknownStatusAsIdle() throws {
        let data = Data(#"[{"identifier":"embedder","status":"idle"}]"#.utf8)

        let info = try #require(RuntimePayloadParser.parseRuntimeInfo(from: data).first)

        #expect(info.activity == .idle)
        #expect(info.queuedRequests == 0)
    }

    @Test
    func clampsNegativeQueueCounts() throws {
        let data = Data(#"[{"identifier":"model","status":"loading","queued":-3}]"#.utf8)

        let info = try #require(RuntimePayloadParser.parseRuntimeInfo(from: data).first)

        #expect(info.activity == .loading)
        #expect(info.queuedRequests == 0)
    }

    @Test
    func ignoresEntriesWithoutAnIdentifier() throws {
        let data = Data(#"[{"status":"generating","queued":1}]"#.utf8)

        let info = try RuntimePayloadParser.parseRuntimeInfo(from: data)

        #expect(info.isEmpty)
    }
}
