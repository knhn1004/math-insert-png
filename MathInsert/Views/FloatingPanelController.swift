import AppKit

class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class FloatingPanelController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    convenience init(contentVC: NSViewController) {
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "MathInsert"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = NSColor(white: 0.12, alpha: 0.72)

        // Add blur behind
        let blur = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 420, height: 520))
        blur.blendingMode = .behindWindow
        blur.material = .hudWindow
        blur.state = .active
        blur.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(blur, positioned: .below, relativeTo: nil)

        panel.contentViewController = contentVC
        panel.center()
        panel.minSize = NSSize(width: 340, height: 420)

        self.init(window: panel)
        panel.delegate = self
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
