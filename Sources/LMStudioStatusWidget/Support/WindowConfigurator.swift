import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ConfiguringView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? ConfiguringView else { return }
        view.configureWindowIfNeeded()
    }
}

private final class ConfiguringView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindowIfNeeded()
    }

    func configureWindowIfNeeded() {
        guard let window else { return }

        window.title = "LM Studio Status"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .normal
        window.collectionBehavior = []

        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    }
}
