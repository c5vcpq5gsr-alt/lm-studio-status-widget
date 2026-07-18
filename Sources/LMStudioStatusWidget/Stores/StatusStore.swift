import Foundation
import SwiftUI

@MainActor
final class StatusStore: ObservableObject {
    @Published private(set) var snapshot: LMStudioSnapshot = .checking
    @Published private(set) var isRefreshing = false

    @Published var baseURLString: String {
        didSet {
            UserDefaults.standard.set(baseURLString, forKey: DefaultsKey.baseURL)
            Task { await refresh() }
        }
    }

    @Published var refreshInterval: Double {
        didSet {
            let clamped = min(max(refreshInterval, 1), 60)
            if clamped != refreshInterval {
                refreshInterval = clamped
                return
            }

            UserDefaults.standard.set(refreshInterval, forKey: DefaultsKey.refreshInterval)
            restartTimer()
        }
    }

    private let client = LMStudioClient()
    private var timer: Timer?
    private var generationDetectedAt: [String: Date] = [:]

    init() {
        let defaults = UserDefaults.standard
        self.baseURLString = defaults.string(forKey: DefaultsKey.baseURL) ?? "http://localhost:1234"

        let storedInterval = defaults.double(forKey: DefaultsKey.refreshInterval)
        self.refreshInterval = storedInterval > 0 ? storedInterval : 3
    }

    var loadedModels: [LMStudioModel] {
        snapshot.loadedModels
    }

    var generatingModels: [LMStudioModel] {
        snapshot.generatingModels
    }

    var menuBarTitle: String {
        switch snapshot.serverState {
        case .checking:
            "LM Studio"
        case .online:
            generatingModels.isEmpty
                ? (loadedModels.isEmpty ? "LM Studio" : "\(loadedModels.count)")
                : "\(generatingModels.count) GEN"
        case .offline:
            "LM Studio"
        }
    }

    var menuBarSystemImage: String {
        switch snapshot.serverState {
        case .checking:
            "arrow.triangle.2.circlepath"
        case .online:
            generatingModels.isEmpty
                ? (loadedModels.isEmpty ? "checkmark.circle" : "checkmark.circle.fill")
                : "waveform.circle.fill"
        case .offline:
            "xmark.circle"
        }
    }

    func start() {
        restartTimer()
        Task { await refresh() }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true

        do {
            let newSnapshot = try await client.fetchSnapshot(baseURLString: baseURLString)
            updateGenerationTracking(for: newSnapshot)
            snapshot = newSnapshot
        } catch {
            generationDetectedAt.removeAll()
            snapshot = LMStudioSnapshot(
                serverState: .offline,
                models: [],
                sourceEndpoint: nil,
                checkedAt: Date(),
                errorMessage: error.localizedDescription
            )
        }

        isRefreshing = false
    }

    func generationStart(for model: LMStudioModel) -> Date? {
        generationDetectedAt[model.id]
    }

    private func updateGenerationTracking(for newSnapshot: LMStudioSnapshot) {
        let generatingIDs = Set(newSnapshot.generatingModels.map(\.id))
        generationDetectedAt = generationDetectedAt.filter { generatingIDs.contains($0.key) }

        for id in generatingIDs where generationDetectedAt[id] == nil {
            generationDetectedAt[id] = Date()
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }
}

private enum DefaultsKey {
    static let baseURL = "lmstudio.baseURL"
    static let refreshInterval = "lmstudio.refreshInterval"
}
