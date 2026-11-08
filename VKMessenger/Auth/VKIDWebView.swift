import SwiftUI
import WebKit

@MainActor
struct VKIDLoginView: View {
    let authURL: URL
    let onResult: (Result<URL, Error>) -> Void

    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            VKIDWebView(url: authURL, isLoading: $isLoading) { result in
                onResult(result)
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Вход через VK ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        onResult(.failure(AuthError.cancelled))
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Открываем VK ID…")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

struct VKIDWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    let onResult: (Result<URL, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = Self.mobileSafariUserAgent
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: VKIDWebView
        private var didComplete = false

        init(_ parent: VKIDWebView) {
            self.parent = parent
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if url.scheme == "http", url.host == "localhost" {
                decisionHandler(.cancel)
                complete(with: .success(url))
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            handle(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            handle(error)
        }

        private func handle(_ error: Error) {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return
            }
            complete(with: .failure(error))
        }

        private func complete(with result: Result<URL, Error>) {
            guard !didComplete else { return }
            didComplete = true
            parent.isLoading = false

            let callback = parent.onResult
            DispatchQueue.main.async {
                callback(result)
            }
        }
    }

    private static let mobileSafariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
}
