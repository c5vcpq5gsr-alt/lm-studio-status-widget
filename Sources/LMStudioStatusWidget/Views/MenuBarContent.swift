import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var store: StatusStore
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Section {
            Label(store.snapshot.serverState.title, systemImage: store.snapshot.serverState.systemImage)

            if store.loadedModels.isEmpty {
                Text(store.snapshot.serverState == .offline ? "Keine Verbindung" : "Keine Modelle geladen")
            } else {
                ForEach(store.loadedModels.prefix(6)) { model in
                    Label(model.name, systemImage: "cpu")
                }
            }
        }

        Divider()

        Button("Fenster anzeigen") {
            openWindow(id: "main")
            WindowPresenter.showMainWindowSoon()
        }

        Button("Aktualisieren") {
            Task { await store.refresh() }
        }

        Button("Einstellungen...") {
            openSettings()
        }

        Button("Beenden") {
            NSApplication.shared.terminate(nil)
        }
    }
}
