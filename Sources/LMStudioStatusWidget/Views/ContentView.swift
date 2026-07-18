import SwiftUI

struct ContentView: View {
    @ObservedObject var store: StatusStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        ZStack {
            Color.clear

            VStack(alignment: .leading, spacing: 14) {
                HeaderView(store: store)

                Divider()

                ModelListView(store: store)

                Spacer(minLength: 0)

                FooterView(store: store)
            }
            .padding(18)
            .frame(width: 360, height: 342, alignment: .topLeading)
            .background {
                WidgetCardBackground()
            }
        }
        .contextMenu {
            Button("Aktualisieren") {
                Task { await store.refresh() }
            }

            Button("Einstellungen...") {
                openSettings()
            }
        }
    }
}

private struct WidgetCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                    .blendMode(.multiply)
            }
            .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 8)
            .compositingGroup()
    }
}

private struct HeaderView: View {
    @ObservedObject var store: StatusStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: store.snapshot.serverState.systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(statusColor)
                .font(.system(size: 28, weight: .semibold))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text("LM Studio")
                    .font(.headline)
                    .lineLimit(1)

                Text(store.snapshot.serverState.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("Aktualisieren")
            .disabled(store.isRefreshing)

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("Einstellungen")
        }
    }

    private var statusColor: Color {
        switch store.snapshot.serverState {
        case .checking:
            .secondary
        case .online:
            .green
        case .offline:
            .red
        }
    }
}

private struct ModelListView: View {
    @ObservedObject var store: StatusStore

    private var models: [LMStudioModel] { store.loadedModels }
    private var state: ServerState { store.snapshot.serverState }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Geladene Modelle")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if state == .offline {
                EmptyStateView(title: "Kein Server erreichbar", systemImage: "wifi.slash")
            } else if models.isEmpty {
                EmptyStateView(title: "Keine Modelle geladen", systemImage: "tray")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(models) { model in
                            ModelRow(model: model, generationStart: store.generationStart(for: model))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 78)
            }
        }
    }
}

private struct ModelRow: View {
    let model: LMStudioModel
    let generationStart: Date?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "cpu")
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if !model.subtitle.isEmpty {
                    Text(model.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if model.isGenerating {
                    GenerationStatusView(
                        startedAt: generationStart,
                        queuedRequests: model.queuedRequests
                    )
                }
            }
        }
    }
}

private struct GenerationStatusView: View {
    let startedAt: Date?
    let queuedRequests: Int

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 5) {
                ProgressView()
                    .controlSize(.mini)

                Text("GEN")
                    .fontWeight(.semibold)

                if let startedAt {
                    Text(Self.elapsed(from: startedAt, to: context.date))
                        .monospacedDigit()
                }

                if queuedRequests > 0 {
                    Text("+\(queuedRequests) wartet")
                }
            }
            .font(.caption)
            .foregroundStyle(.green)
        }
    }

    private static func elapsed(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .center)
    }
}

private struct FooterView: View {
    @ObservedObject var store: StatusStore

    var body: some View {
        HStack(spacing: 8) {
            Text(store.snapshot.checkedAt.map(Self.timeFormatter.string(from:)) ?? "--:--")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if let endpoint = store.snapshot.sourceEndpoint {
                Text(endpoint)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            } else if let error = store.snapshot.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(Int(store.refreshInterval))s")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
}
