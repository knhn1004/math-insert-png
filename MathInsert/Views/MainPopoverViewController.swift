import AppKit
import WebKit

// MARK: - Neobrutalist styled views

class NeoBox: NSView {
    var fillColor: NSColor = NSColor(white: 1.0, alpha: 0.08) {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        fillColor.setFill()
        let path = NSBezierPath(rect: bounds)
        path.fill()

        NSColor(white: 1.0, alpha: 0.2).setStroke()
        let border = NSBezierPath(rect: bounds.insetBy(dx: 1, dy: 1))
        border.lineWidth = 1.5
        border.stroke()
    }
}

class NeoButton: NSButton {
    var bgColor: NSColor = NSColor(white: 1.0, alpha: 0.15)
    private var isPressed = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isBordered = false
        wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let mainRect = bounds

        // Background
        let bg = isPressed ? bgColor.withAlphaComponent(bgColor.alphaComponent * 0.6) : bgColor
        bg.setFill()
        NSBezierPath(rect: mainRect).fill()

        // Border
        NSColor(white: 1.0, alpha: 0.3).setStroke()
        let border = NSBezierPath(rect: mainRect.insetBy(dx: 0.75, dy: 0.75))
        border.lineWidth = 1.5
        border.stroke()

        // Title
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .heavy),
            .foregroundColor: NSColor.white,
            .paragraphStyle: style
        ]
        let titleStr = title as NSString
        let titleSize = titleStr.size(withAttributes: attrs)
        let titleRect = NSRect(
            x: mainRect.origin.x,
            y: mainRect.origin.y + (mainRect.height - titleSize.height) / 2,
            width: mainRect.width,
            height: titleSize.height
        )
        titleStr.draw(in: titleRect, withAttributes: attrs)
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
        needsDisplay = true
        super.mouseDown(with: event)
        isPressed = false
        needsDisplay = true
    }

    override var intrinsicContentSize: NSSize {
        let titleSize = (title as NSString).size(withAttributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .heavy)
        ])
        return NSSize(width: titleSize.width + 24, height: 28)
    }
}

class NeoTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        NSColor(white: 1.0, alpha: 0.15).setFill()
        NSBezierPath(rect: bounds).fill()

        NSColor(white: 1.0, alpha: 0.3).setStroke()
        let border = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()
    }

    override var interiorBackgroundStyle: NSView.BackgroundStyle {
        return isSelected ? .emphasized : .normal
    }
}

class NeoColorToggle: NSView {
    var selectedIndex = 0 { didSet { needsDisplay = true } }
    var onToggle: ((Int) -> Void)?

    private let borderW: CGFloat = 2.5

    override init(frame: NSRect) {
        super.init(frame: frame)
        let click = NSClickGestureRecognizer(target: self, action: #selector(clicked(_:)))
        addGestureRecognizer(click)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: 100, height: 30) }

    override func draw(_ dirtyRect: NSRect) {
        let half = bounds.width / 2
        let h = bounds.height

        // Left cell: white bg, black "A" (= export black strokes)
        let leftRect = NSRect(x: 0, y: 0, width: half, height: h)
        (selectedIndex == 0 ? NSColor(white: 1.0, alpha: 0.95) : NSColor(white: 1.0, alpha: 0.15)).setFill()
        NSBezierPath(rect: leftRect).fill()
        drawLabel("A", in: leftRect, color: selectedIndex == 0 ? .black : NSColor(white: 1.0, alpha: 0.4))

        // Right cell: dark bg, white "A" (= export white strokes)
        let rightRect = NSRect(x: half, y: 0, width: half, height: h)
        (selectedIndex == 1 ? NSColor(white: 0.1, alpha: 0.95) : NSColor(white: 0.0, alpha: 0.3)).setFill()
        NSBezierPath(rect: rightRect).fill()
        drawLabel("A", in: rightRect, color: selectedIndex == 1 ? .white : NSColor(white: 1.0, alpha: 0.4))

        // Border around whole thing
        NSColor(white: 1.0, alpha: 0.3).setStroke()
        let outer = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        outer.lineWidth = 1.5
        outer.stroke()

        // Divider
        let divider = NSBezierPath()
        divider.move(to: NSPoint(x: half, y: 0))
        divider.line(to: NSPoint(x: half, y: h))
        divider.lineWidth = 1
        divider.stroke()
    }

    private func drawLabel(_ text: String, in rect: NSRect, color: NSColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .black),
            .foregroundColor: color
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let point = NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
        (text as NSString).draw(at: point, withAttributes: attrs)
    }

    @objc private func clicked(_ gesture: NSClickGestureRecognizer) {
        let loc = gesture.location(in: self)
        let newIndex = loc.x < bounds.width / 2 ? 0 : 1
        if newIndex != selectedIndex {
            selectedIndex = newIndex
            onToggle?(selectedIndex)
        }
    }
}

// MARK: - Main VC

class MainPopoverViewController: NSViewController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate, MathWebViewDelegate {
    private var inputField: NSTextField!
    private var mathWebView: MathWebView!
    private var scaleSlider: NSSlider!
    private var scaleLabel: NSTextField!
    private var historyTableView: NSTableView!
    private var copyButton: NeoButton!
    private var popOutButton: NeoButton!
    private var colorToggle: NeoColorToggle!
    private var copiedLabel: NSTextField!
    private var copiedTimer: Timer?
    private var previewBox: NeoBox!
    private var historyBox: NeoBox!
    private var exportWhite = false

    // Translucent neo palette
    private let bgColor = NSColor.clear
    private let previewBg = NSColor(white: 1.0, alpha: 0.1)
    private let accentYellow = NSColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1.0)
    private let accentPink = NSColor(red: 1.0, green: 0.45, blue: 0.55, alpha: 1.0)
    private let inkColor = NSColor(white: 1.0, alpha: 0.95)
    private let dimColor = NSColor(white: 1.0, alpha: 0.5)
    private let borderColor = NSColor(white: 1.0, alpha: 0.25)

    var onPopOut: (() -> Void)?

    private let scaleKey = "math_render_scale"
    private var currentScale: CGFloat {
        get {
            let val = UserDefaults.standard.double(forKey: scaleKey)
            return val > 0 ? CGFloat(val) : 32
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: scaleKey)
        }
    }

    override func loadView() {
        let v = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 500))
        view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateDarkMode()

        NotificationCenter.default.addObserver(
            self, selector: #selector(appearanceDidChange),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(inputField)
    }

    @objc private func appearanceDidChange() {
        updateDarkMode()
    }

    private func updateDarkMode() {
        // Translucent dark background — always show white math text
        mathWebView.setTextColor(true)
    }

    private func setupUI() {
        let pad: CGFloat = 16

        // Title label
        let titleLabel = NSTextField(labelWithString: "MATH INSERT")
        titleLabel.font = .systemFont(ofSize: 16, weight: .black)
        titleLabel.textColor = inkColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Buttons
        copyButton = NeoButton(frame: .zero)
        copyButton.title = "COPY PNG"
        copyButton.bgColor = accentPink.withAlphaComponent(0.8)
        copyButton.target = self
        copyButton.action = #selector(copyClicked)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(copyButton)

        copiedLabel = NSTextField(labelWithString: "")
        copiedLabel.font = .systemFont(ofSize: 12, weight: .black)
        copiedLabel.textColor = NSColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1.0)
        copiedLabel.translatesAutoresizingMaskIntoConstraints = false
        copiedLabel.isHidden = true
        view.addSubview(copiedLabel)

        // Input field — translucent with border
        inputField = NSTextField()
        inputField.placeholderString = "\\frac{a}{b} + \\sqrt{x}"
        inputField.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        inputField.textColor = .white
        inputField.backgroundColor = NSColor(white: 1.0, alpha: 0.08)
        inputField.drawsBackground = true
        inputField.isBordered = false
        inputField.focusRingType = .none
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.delegate = self
        inputField.wantsLayer = true
        inputField.layer?.borderWidth = 2
        inputField.layer?.borderColor = borderColor.cgColor
        inputField.layer?.cornerRadius = 0
        inputField.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.08).cgColor

        // Input container (no shadow for translucent style)
        let inputContainer = NSView()
        inputContainer.wantsLayer = true
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputField)

        // Preview box
        previewBox = NeoBox()
        previewBox.fillColor = previewBg
        previewBox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewBox)

        mathWebView = MathWebView()
        mathWebView.mathDelegate = self
        mathWebView.translatesAutoresizingMaskIntoConstraints = false
        previewBox.addSubview(mathWebView)

        // Scale row
        let sizeLabel = NSTextField(labelWithString: "SIZE")
        sizeLabel.font = .systemFont(ofSize: 10, weight: .black)
        sizeLabel.textColor = inkColor
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sizeLabel)

        scaleSlider = NSSlider(value: Double(currentScale), minValue: 16, maxValue: 96, target: self, action: #selector(scaleChanged))
        scaleSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scaleSlider)

        scaleLabel = NSTextField(labelWithString: "\(Int(currentScale))px")
        scaleLabel.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        scaleLabel.textColor = inkColor
        scaleLabel.alignment = .right
        scaleLabel.setContentHuggingPriority(.required, for: .horizontal)
        scaleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scaleLabel)

        // Export color toggle
        colorToggle = NeoColorToggle(frame: .zero)
        colorToggle.translatesAutoresizingMaskIntoConstraints = false
        colorToggle.onToggle = { [weak self] index in
            self?.exportWhite = index == 1
        }
        view.addSubview(colorToggle)

        let exportLabel = NSTextField(labelWithString: "EXPORT")
        exportLabel.font = .systemFont(ofSize: 10, weight: .black)
        exportLabel.textColor = inkColor
        exportLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exportLabel)

        // History section
        let historyTitle = NSTextField(labelWithString: "HISTORY")
        historyTitle.font = .systemFont(ofSize: 10, weight: .black)
        historyTitle.textColor = inkColor
        historyTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(historyTitle)

        let clearButton = NSButton(title: "CLEAR", target: self, action: #selector(clearHistory))
        clearButton.isBordered = false
        clearButton.font = .systemFont(ofSize: 10, weight: .black)
        clearButton.contentTintColor = accentPink
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearButton)

        // Thick separator
        let sep = NSView()
        sep.wantsLayer = true
        sep.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.15).cgColor
        sep.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sep)

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        view.addSubview(scrollView)

        historyTableView = NSTableView()
        historyTableView.dataSource = self
        historyTableView.delegate = self
        historyTableView.headerView = nil
        historyTableView.rowHeight = 30
        historyTableView.selectionHighlightStyle = .none
        historyTableView.backgroundColor = .clear

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("latex"))
        column.title = "Expression"
        historyTableView.addTableColumn(column)
        scrollView.documentView = historyTableView

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteHistoryItem), keyEquivalent: ""))
        historyTableView.menu = menu

        // Layout
        NSLayoutConstraint.activate([
            // Title + buttons row
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 36),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            copyButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            copyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad - 4),

            copiedLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            copiedLabel.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -10),

            // Input field with shadow
            inputContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            inputContainer.heightAnchor.constraint(equalToConstant: 38),

            inputField.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor),
            inputField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor),
            inputField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),

            // Preview
            previewBox.topAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: 12),
            previewBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            previewBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            previewBox.heightAnchor.constraint(equalToConstant: 160),

            mathWebView.topAnchor.constraint(equalTo: previewBox.topAnchor, constant: 8),
            mathWebView.leadingAnchor.constraint(equalTo: previewBox.leadingAnchor, constant: 8),
            mathWebView.trailingAnchor.constraint(equalTo: previewBox.trailingAnchor, constant: -12),
            mathWebView.bottomAnchor.constraint(equalTo: previewBox.bottomAnchor, constant: -12),

            // Scale row
            sizeLabel.topAnchor.constraint(equalTo: previewBox.bottomAnchor, constant: 12),
            sizeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            scaleSlider.centerYAnchor.constraint(equalTo: sizeLabel.centerYAnchor),
            scaleSlider.leadingAnchor.constraint(equalTo: sizeLabel.trailingAnchor, constant: 8),
            scaleSlider.trailingAnchor.constraint(equalTo: scaleLabel.leadingAnchor, constant: -8),

            scaleLabel.centerYAnchor.constraint(equalTo: sizeLabel.centerYAnchor),
            scaleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            scaleLabel.widthAnchor.constraint(equalToConstant: 40),

            // Export color toggle
            exportLabel.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 12),
            exportLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            colorToggle.centerYAnchor.constraint(equalTo: exportLabel.centerYAnchor),
            colorToggle.leadingAnchor.constraint(equalTo: exportLabel.trailingAnchor, constant: 8),
            colorToggle.widthAnchor.constraint(equalToConstant: 80),
            colorToggle.heightAnchor.constraint(equalToConstant: 26),

            // Separator + History
            sep.topAnchor.constraint(equalTo: exportLabel.bottomAnchor, constant: 10),
            sep.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            sep.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            sep.heightAnchor.constraint(equalToConstant: 2.5),

            historyTitle.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 8),
            historyTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            clearButton.centerYAnchor.constraint(equalTo: historyTitle.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            scrollView.topAnchor.constraint(equalTo: historyTitle.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -pad),
        ])
    }

    // MARK: - Actions

    @objc private func popOutClicked() {
        onPopOut?()
    }

    @objc private func copyClicked() {
        copyCurrentExpression()
    }


    func copyCurrentExpression() {
        let latex = inputField.stringValue
        guard !latex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let exportColor = exportWhite ? "#ffffff" : "#000000"
        mathWebView.captureTransparentPNG(exportColor: exportColor) { [weak self] data in
            guard let data = data else { return }
            PNGExporter.copyToClipboard(data)
            HistoryManager.shared.add(latex)
            DispatchQueue.main.async {
                self?.historyTableView.reloadData()
                self?.showCopiedFeedback()
            }
        }
    }

    private func showCopiedFeedback() {
        copiedLabel.stringValue = "COPIED!"
        copiedLabel.isHidden = false
        copiedTimer?.invalidate()
        copiedTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.copiedLabel.isHidden = true
        }
    }

    @objc private func scaleChanged() {
        let scale = CGFloat(scaleSlider.integerValue)
        scaleLabel.stringValue = "\(Int(scale))px"
        currentScale = scale
        mathWebView.updateExpression(inputField.stringValue, scale: scale)
    }

    func adjustScale(by delta: CGFloat) {
        let newScale = max(16, min(96, currentScale + delta))
        currentScale = newScale
        scaleSlider.doubleValue = Double(newScale)
        scaleLabel.stringValue = "\(Int(newScale))px"
        mathWebView.updateExpression(inputField.stringValue, scale: newScale)
    }

    @objc private func clearHistory() {
        HistoryManager.shared.clear()
        historyTableView.reloadData()
    }

    @objc private func deleteHistoryItem() {
        let row = historyTableView.clickedRow
        guard row >= 0 else { return }
        HistoryManager.shared.remove(at: row)
        historyTableView.reloadData()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        let latex = inputField.stringValue
        mathWebView.updateExpression(latex, scale: currentScale)
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return HistoryManager.shared.expressions.count
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier("HistoryCell")
        var cell = tableView.makeView(withIdentifier: id, owner: nil) as? NSTextField
        if cell == nil {
            cell = NSTextField(labelWithString: "")
            cell?.identifier = id
            cell?.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
            cell?.textColor = inkColor
            cell?.lineBreakMode = .byTruncatingTail
        }
        let expressions = HistoryManager.shared.expressions
        if row < expressions.count {
            cell?.stringValue = expressions[row].latex
        }
        return cell
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let id = NSUserInterfaceItemIdentifier("NeoRow")
        var rowView = tableView.makeView(withIdentifier: id, owner: nil) as? NeoTableRowView
        if rowView == nil {
            rowView = NeoTableRowView()
            rowView?.identifier = id
        }
        return rowView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = historyTableView.selectedRow
        guard row >= 0 else { return }
        let expressions = HistoryManager.shared.expressions
        guard row < expressions.count else { return }
        inputField.stringValue = expressions[row].latex
        mathWebView.updateExpression(expressions[row].latex, scale: currentScale)
    }

    // MARK: - MathWebViewDelegate

    func mathWebViewDidFinishRender(_ webView: MathWebView) {
    }

    // MARK: - Keyboard handling

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            view.window?.close()
        } else {
            super.keyDown(with: event)
        }
    }
}
