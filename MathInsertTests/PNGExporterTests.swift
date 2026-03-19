import XCTest
@testable import MathInsert
import AppKit

final class PNGExporterTests: XCTestCase {

    func testCopyToClipboardWritesPNGData() {
        // Create a minimal valid 1x1 PNG
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 1, height: 1))
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            XCTFail("Failed to create PNG data")
            return
        }

        PNGExporter.copyToClipboard(pngData)

        let pasteboard = NSPasteboard.general
        let result = pasteboard.data(forType: .png)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, pngData)
    }
}
