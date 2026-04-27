import SwiftUI
import WebKit

@MainActor
class WebViewNavigator: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var currentURL: URL?

    fileprivate weak var webView: WKWebView?

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }

    func extractPageContent() async -> (text: String, title: String)? {
        guard let webView else { return nil }
        let js = """
        (function() {
            var title = document.title || '';
            var body = document.body ? document.body.innerText : '';
            return JSON.stringify({title: title, body: body.substring(0, 30000)});
        })()
        """
        do {
            let result = try await webView.evaluateJavaScript(js)
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let dict = try JSONSerialization.jsonObject(with: data) as? [String: String]
            else { return nil }
            return (text: dict["body"] ?? "", title: dict["title"] ?? "")
        } catch {
            print("JS extraction failed: \(error)")
            return nil
        }
    }
}

struct WebView: NSViewRepresentable {
    let url: URL
    let navigator: WebViewNavigator

    func makeCoordinator() -> Coordinator {
        Coordinator(navigator: navigator)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        navigator.webView = webView
        context.coordinator.observe(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        navigator.webView = webView
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let navigator: WebViewNavigator
        private var backObservation: NSKeyValueObservation?
        private var forwardObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?

        init(navigator: WebViewNavigator) {
            self.navigator = navigator
        }

        func observe(_ webView: WKWebView) {
            backObservation = webView.observe(\.canGoBack, options: .new) { [weak self] _, change in
                Task { @MainActor in self?.navigator.canGoBack = change.newValue ?? false }
            }
            forwardObservation = webView.observe(\.canGoForward, options: .new) { [weak self] _, change in
                Task { @MainActor in self?.navigator.canGoForward = change.newValue ?? false }
            }
            urlObservation = webView.observe(\.url, options: .new) { [weak self] _, change in
                Task { @MainActor in self?.navigator.currentURL = change.newValue ?? nil }
            }
        }
    }
}
