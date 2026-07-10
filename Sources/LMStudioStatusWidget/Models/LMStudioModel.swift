import Foundation

struct LMStudioModel: Identifiable, Equatable {
    let id: String
    let name: String
    let modelKey: String?
    let type: String?
    let contextLength: Int?
    let loadedInstances: Int

    var subtitle: String {
        var parts: [String] = []

        if let type, !type.isEmpty {
            parts.append(type.uppercased())
        }

        if let contextLength, contextLength > 0 {
            parts.append("\(contextLength.formatted()) ctx")
        }

        if loadedInstances > 1 {
            parts.append("\(loadedInstances) Instanzen")
        }

        return parts.joined(separator: " / ")
    }
}

struct LMStudioSnapshot: Equatable {
    var serverState: ServerState
    var models: [LMStudioModel]
    var sourceEndpoint: String?
    var checkedAt: Date?
    var errorMessage: String?

    static let checking = LMStudioSnapshot(
        serverState: .checking,
        models: [],
        sourceEndpoint: nil,
        checkedAt: nil,
        errorMessage: nil
    )

    var loadedModels: [LMStudioModel] {
        models
            .filter { $0.loadedInstances > 0 }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

enum ServerState: Equatable {
    case checking
    case online
    case offline

    var title: String {
        switch self {
        case .checking:
            "Pruefe..."
        case .online:
            "Server laeuft"
        case .offline:
            "Server aus"
        }
    }

    var systemImage: String {
        switch self {
        case .checking:
            "arrow.triangle.2.circlepath"
        case .online:
            "checkmark.circle.fill"
        case .offline:
            "xmark.circle.fill"
        }
    }
}
