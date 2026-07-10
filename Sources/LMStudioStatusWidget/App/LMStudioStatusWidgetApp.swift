import AppKit
import SwiftUI

@main
struct LMStudioStatusWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = StatusStore()

    var body: some Scene {
        Window("LM Studio Status", id: "main") {
            ContentView(store: store)
                .frame(width: 396, height: 378)
                .background(WindowConfigurator())
                .task {
                    store.start()
                }
        }
        .defaultLaunchBehavior(.presented)
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("LM Studio") {
                Button("Aktualisieren") {
                    Task { await store.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])

                SettingsLink {
                    Text("Einstellungen...")
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }

        MenuBarExtra {
            MenuBarContent(store: store)
        } label: {
            Label(store.menuBarTitle, systemImage: store.menuBarSystemImage)
                .background(LaunchWindowPresenter())
        }

        Settings {
            SettingsView(store: store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        WindowPresenter.showMainWindowSoon()
    }
}
