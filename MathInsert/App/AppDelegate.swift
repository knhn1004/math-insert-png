import AppKit
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMainMenu()
        statusBarController = StatusBarController()
        registerGlobalHotkey()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(smartCopy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        let viewMenu = NSMenu(title: "View")
        let zoomIn = NSMenuItem(title: "Increase Size", action: #selector(increaseSize(_:)), keyEquivalent: "+")
        zoomIn.keyEquivalentModifierMask = .command
        viewMenu.addItem(zoomIn)
        // Also handle Cmd+= (same physical key without shift)
        let zoomInAlt = NSMenuItem(title: "Increase Size", action: #selector(increaseSize(_:)), keyEquivalent: "=")
        zoomInAlt.keyEquivalentModifierMask = .command
        viewMenu.addItem(zoomInAlt)
        let zoomOut = NSMenuItem(title: "Decrease Size", action: #selector(decreaseSize(_:)), keyEquivalent: "-")
        zoomOut.keyEquivalentModifierMask = .command
        viewMenu.addItem(zoomOut)

        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func increaseSize(_ sender: Any?) {
        statusBarController?.adjustScale(by: 4)
    }

    @objc private func decreaseSize(_ sender: Any?) {
        statusBarController?.adjustScale(by: -4)
    }

    @objc private func smartCopy(_ sender: Any?) {
        // If text field has a selection, do normal text copy
        if let fieldEditor = NSApp.keyWindow?.firstResponder as? NSTextView,
           fieldEditor.selectedRange().length > 0 {
            fieldEditor.copy(sender)
            return
        }
        // Otherwise copy PNG
        statusBarController?.copyPNG()
    }

    private func registerGlobalHotkey() {
        // Register Ctrl+Shift+M using Carbon hot key API (works without Accessibility permissions)
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D495F48), // "MI_H"
                                      id: 1)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        // Install handler
        let handlerRef = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            delegate.statusBarController?.toggle()
            return noErr
        }, 1, &eventType, handlerRef, nil)

        // Ctrl+Shift+M: kVK_ANSI_M = 0x2E
        let modifiers = UInt32(controlKey | shiftKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_M), modifiers, hotKeyID,
                           GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
