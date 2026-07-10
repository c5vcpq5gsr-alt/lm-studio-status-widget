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

                return LMStudioSnapshot(
                    serverState: .online,
                    models: models,
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
