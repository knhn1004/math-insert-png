import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
    private var floatingPanel: FloatingPanelController?
    private var mainVC: MainPopoverViewController
    private var isFloating = false

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        mainVC = MainPopoverViewController()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sum", accessibilityDescription: "MathInsert")
        }

        statusItem.menu = buildMenu()

        mainVC.onPopOut = { [weak self] in
            self?.popOut()
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show Panel", action: #selector(showPanel(_:)), keyEquivalent: "")
        showItem.target = self
        showItem.image = NSImage(systemSymbolName: "rectangle.and.pencil.and.ellipsis", accessibilityDescription: nil)
        menu.addItem(showItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "About MathInsert", action: #selector(showAbout(_:)), keyEquivalent: "")
        aboutItem.target = self
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit MathInsert", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    func adjustScale(by delta: CGFloat) {
        mainVC.adjustScale(by: delta)
    }

    func copyPNG() {
        mainVC.copyCurrentExpression()
    }

    func toggle() {
        if let panel = floatingPanel, let window = panel.window, window.isVisible {
            if window == NSApp.keyWindow {
                window.orderOut(nil)
            } else {
                window.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            isFloating = true
            showFloatingPanel()
        }
    }

    @objc private func showPanel(_ sender: AnyObject?) {
        isFloating = true
        showFloatingPanel()
    }

    @objc private func showAbout(_ sender: AnyObject?) {
        let alert = NSAlert()
        alert.messageText = "MathInsert"
        alert.informativeText = "Type LaTeX, copy as PNG.\nVersion 1.0\n\nShortcut: Ctrl+Shift+M"
        alert.alertStyle = .informational
        alert.icon = NSApp.applicationIconImage
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitApp(_ sender: AnyObject?) {
        NSApp.terminate(nil)
    }

    func popOut() {
        isFloating = true
        showFloatingPanel()
    }

    private func showFloatingPanel() {
        if floatingPanel == nil {
            floatingPanel = FloatingPanelController(contentVC: mainVC)
            floatingPanel?.onClose = { [weak self] in
                self?.isFloating = false
                self?.floatingPanel = nil
            }
        }
        floatingPanel?.showWindow(nil)
        floatingPanel?.window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func popBack() {
        floatingPanel?.close()
        isFloating = false
        floatingPanel = nil
    }
}
