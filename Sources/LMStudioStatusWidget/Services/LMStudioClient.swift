import Foundation

final class LMStudioClient: @unchecked Sendable {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 2
        configuration.timeoutIntervalForResource = 3
        self.session = URLSession(configuration: configuration)
    }

    func fetchSnapshot(baseURLString: String) async throws -> LMStudioSnapshot {
        guard let baseURL = normalizedBaseURL(from: baseURLString) else {
            throw LMStudioClientError.invalidBaseURL
        }

        var lastError: Error?
        let endpoints = [
            Endpoint(path: "/api/v1/models", assumesLoadedModels: false),
            Endpoint(path: "/v1/models", assumesLoadedModels: true)
        ]

        for endpoint in endpoints {
            do {
                let data = try await fetch(endpoint.path, from: baseURL)
                let models = try ModelPayloadParser.parseModels(
                    from: data,
                    assumesLoadedModels: endpoint.assumesLoadedModels
                )
                let enrichedModels = await enrichWithLocalRuntimeInfo(models, baseURL: baseURL)

                return LMStudioSnapshot(
                    serverState: .online,
                    models: enrichedModels,
                    sourceEndpoint: endpoint.path,
                    checkedAt: Date(),
                    errorMessage: nil
                )
            } catch LMStudioClientError.httpStatus(let status) where status == 404 {
                lastError = LMStudioClientError.httpStatus(status)
                continue
            } catch {
                lastError = error
                continue
            }
        }

        throw lastError ?? LMStudioClientError.noUsableResponse
    }

    private func fetch(_ path: String, from baseURL: URL) async throws -> Data {
        guard let url = URL(string: baseURL.absoluteString + path) else {
            throw LMStudioClientError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LMStudioClientError.noUsableResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw LMStudioClientError.httpStatus(httpResponse.statusCode)
        }

        return data
    }

    private func normalizedBaseURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme: String
        if trimmed.contains("://") {
            withScheme = trimmed
        } else {
            withScheme = "http://\(trimmed)"
        }

        return URL(string: withScheme.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    private func enrichWithLocalRuntimeInfo(
        _ models: [LMStudioModel],
        baseURL: URL
    ) async -> [LMStudioModel] {
        guard Self.isLocal(baseURL), let executableURL = Self.lmsExecutableURL() else {
            return models
        }

        let runtimeInfo = await Task.detached(priority: .utility) {
            Self.fetchRuntimeInfo(executableURL: executableURL)
        }.value

        guard !runtimeInfo.isEmpty else { return models }

        let infoByIdentifier = Dictionary(uniqueKeysWithValues: runtimeInfo.map { ($0.identifier, $0) })
        return models.map { model in
            let identifiers = [model.id, model.modelKey, model.name].compactMap { $0 }
            guard let runtime = identifiers.compactMap({ infoByIdentifier[$0] }).first else {
                return model
            }
            return model.applying(runtime: runtime)
        }
    }

    private static func isLocal(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return ["localhost", "127.0.0.1", "::1"].contains(host)
    }

    private static func lmsExecutableURL() -> URL? {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            homeDirectory.appending(path: ".lmstudio/bin/lms"),
            URL(fileURLWithPath: "/opt/homebrew/bin/lms"),
            URL(fileURLWithPath: "/usr/local/bin/lms")
        ]

        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    private static func fetchRuntimeInfo(executableURL: URL) -> [LMStudioRuntimeInfo] {
        let process = Process()
        let output = Pipe()
        process.executableURL = executableURL
        process.arguments = ["ps", "--json"]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()

            let timeout = DispatchWorkItem {
                if process.isRunning {
                    process.terminate()
                }
            }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.5, execute: timeout)

            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            timeout.cancel()

            guard process.terminationStatus == 0 else { return [] }
            return (try? RuntimePayloadParser.parseRuntimeInfo(from: data)) ?? []
        } catch {
            return []
        }
    }
}

private struct Endpoint {
    let path: String
    let assumesLoadedModels: Bool
}

enum LMStudioClientError: LocalizedError {
    case invalidBaseURL
    case httpStatus(Int)
    case noUsableResponse

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            "Ungueltige Server-Adresse"
        case .httpStatus(let status):
            "HTTP \(status)"
        case .noUsableResponse:
            "Keine verwertbare Antwort"
        }
    }
}
