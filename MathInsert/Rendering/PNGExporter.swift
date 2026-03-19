import AppKit

enum PNGExporter {
    static func copyToClipboard(_ pngData: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(pngData, forType: .png)
    }
}
