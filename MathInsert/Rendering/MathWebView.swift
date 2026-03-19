import AppKit
import WebKit

protocol MathWebViewDelegate: AnyObject {
    func mathWebViewDidFinishRender(_ webView: MathWebView)
}

class MathWebView: WKWebView, WKNavigationDelegate, WKScriptMessageHandler {
    weak var mathDelegate: MathWebViewDelegate?
    private var isPageLoaded = false
    private var pendingExpression: String?
    private var pendingScale: CGFloat?
    private var pendingDark: Bool?

    init() {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        config.userContentController = userContentController
        super.init(frame: .zero, configuration: config)

        userContentController.add(self, name: "renderComplete")

        navigationDelegate = self
        setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) {
            underPageBackgroundColor = .clear
        }

        loadHTMLContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadHTMLContent() {
        let htmlPath = Bundle.main.path(forResource: "math_render", ofType: "html")
            ?? Bundle.main.path(forResource: "math_render", ofType: "html", inDirectory: "Resources")

        if let path = htmlPath {
            let url = URL(fileURLWithPath: path)
            loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            // Fallback: load HTML string directly
            let html = MathWebView.fallbackHTML()
            loadHTMLString(html, baseURL: nil)
        }
    }

    func updateExpression(_ latex: String, scale: CGFloat = 32) {
        guard isPageLoaded else {
            pendingExpression = latex
            pendingScale = scale
            return
        }
        let escaped = latex
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        evaluateJavaScript("renderLatex('\(escaped)', \(scale))")
    }

    func captureTransparentPNG(exportColor: String = "#000000", completion: @escaping (Data?) -> Void) {
        evaluateJavaScript("setColorForExport('\(exportColor)')") { [weak self] _, _ in
            self?.performSnapshot(completion: completion)
        }
    }

    private func performSnapshot(completion: @escaping (Data?) -> Void) {
        evaluateJavaScript("getBoundingRect()") { [weak self] result, error in
            guard let self = self,
                  let dict = result as? [String: CGFloat],
                  let x = dict["x"],
                  let y = dict["y"],
                  let width = dict["width"],
                  let height = dict["height"],
                  width > 0, height > 0 else {
                completion(nil)
                return
            }

            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            let config = WKSnapshotConfiguration()
            config.rect = CGRect(x: x, y: y, width: width, height: height)
            config.snapshotWidth = NSNumber(value: Double(width) * Double(scale))

            self.takeSnapshot(with: config) { image, error in
                guard let image = image else {
                    completion(nil)
                    return
                }
                guard let tiffData = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmap.representation(using: .png, properties: [:]) else {
                    completion(nil)
                    return
                }
                // Restore display color after snapshot
                self.evaluateJavaScript("applyColor()")
                completion(pngData)
            }
        }
    }

    func setTextColor(_ isDark: Bool) {
        guard isPageLoaded else {
            pendingDark = isDark
            return
        }
        let color = isDark ? "#ffffff" : "#000000"
        evaluateJavaScript("setTextColor('\(color)')")
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("MathWebView navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("MathWebView provisional navigation failed: \(error.localizedDescription)")
        // Load fallback HTML string if file loading fails
        let html = MathWebView.fallbackHTML()
        loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isPageLoaded = true
        if let isDark = pendingDark {
            setTextColor(isDark)
            pendingDark = nil
        }
        if let expr = pendingExpression {
            updateExpression(expr, scale: pendingScale ?? 32)
            pendingExpression = nil
            pendingScale = nil
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "renderComplete" {
            mathDelegate?.mathWebViewDidFinishRender(self)
        }
    }

    // MARK: - Fallback HTML

    static func fallbackHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            * { margin: 0; padding: 0; }
            html, body { background: transparent; overflow: hidden; }
            #math-output { display: inline-block; padding: 10px; }
        </style>
        <style id="color-style">
            #math-output, #math-output svg, #math-output svg * {
                color: #000000 !important;
                fill: currentColor !important;
                stroke: currentColor !important;
            }
        </style>
        <script>
            window.MathJax = {
                tex: { inlineMath: [['$', '$'], ['\\\\(', '\\\\)']] },
                svg: { fontCache: 'none' },
                startup: {
                    ready: function() {
                        MathJax.startup.defaultReady();
                        MathJax.startup.promise.then(function() {
                            window.webkit.messageHandlers.renderComplete.postMessage('ready');
                        });
                    }
                }
            };
        </script>
        <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js" async></script>
        </head>
        <body>
        <div id="math-output"></div>
        <script>
            var displayColor = '#000000';
            function updateColorStyle(color) {
                document.getElementById('color-style').textContent =
                    '#math-output, #math-output svg, #math-output svg * { ' +
                    'color: ' + color + ' !important; ' +
                    'fill: currentColor !important; ' +
                    'stroke: currentColor !important; }';
            }
            function renderLatex(latex, scale) {
                var el = document.getElementById('math-output');
                el.style.fontSize = scale + 'px';
                el.innerHTML = '$$' + latex + '$$';
                if (window.MathJax && MathJax.typesetPromise) {
                    MathJax.typesetPromise([el]).then(function() {
                        updateColorStyle(displayColor);
                        window.webkit.messageHandlers.renderComplete.postMessage('done');
                    }).catch(function(err) {
                        console.error('MathJax error:', err);
                    });
                }
            }
            function getBoundingRect() {
                var el = document.getElementById('math-output');
                var rect = el.getBoundingClientRect();
                return { x: rect.left, y: rect.top, width: rect.width, height: rect.height };
            }
            function setTextColor(color) { displayColor = color; updateColorStyle(color); }
            function setColorForExport(color) { updateColorStyle(color); }
            function applyColor() { updateColorStyle(displayColor); }
        </script>
        </body>
        </html>
        """;
    }
}
