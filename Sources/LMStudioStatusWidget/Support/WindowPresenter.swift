import AppKit
import SwiftUI

@MainActor
enum WindowPresenter {
    static func showMainWindowSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showMainWindow()
        }
    }

    static func showMainWindow() {
        NSApp.setActivationPolicy(.accessory)

        let targetWindow = NSApp.windows.first { window in
            window.title == "LM Studio Status"
        } ?? NSApp.windows.first { window in
            String(describing: type(of: window)).contains("SwiftUI")
        }

        targetWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct LaunchWindowPresenter: View {
    @Environment(\.openWindow) private var openWindow
    @State private var didRequestWindow = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task {
                guard !didRequestWindow else { return }
                didRequestWindow = true
                openWindow(id: "main")
                WindowPresenter.showMainWindowSoon()
            }
    }
}
