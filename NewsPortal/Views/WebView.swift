import SwiftUI
import WebKit

@MainActor
class WebViewNavigator: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false

    fileprivate weak var webView: WKWebView?

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
}

struct WebView: NSViewRepresentable {
    let url: URL
    let navigator: WebViewNavigator

    func makeCoordinator() -> Coordinator {
        Coordinator(navigator: navigator)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
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
        }
    }
}
