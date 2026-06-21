import SwiftUI
import WebKit

struct SamVitalsWebView: View {
    let url: URL

    var body: some View {
        WebViewRepresentable(url: url)
    }
}

private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(initialURL: url)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.refresh), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        context.coordinator.webView = webView

        let loadingView = WebLoadingView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        webView.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
        ])
        context.coordinator.loadingView = loadingView

        let errorView = WebNetworkErrorView()
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.retryButton.addTarget(
            context.coordinator,
            action: #selector(Coordinator.retry),
            for: .touchUpInside
        )
        webView.addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: webView.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        ])
        context.coordinator.errorView = errorView
        context.coordinator.load(url, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.initialURL != url else { return }
        context.coordinator.initialURL = url
        context.coordinator.load(url, in: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        weak var loadingView: WebLoadingView?
        weak var errorView: WebNetworkErrorView?
        var initialURL: URL
        var allowedHost: String? { initialURL.host }

        init(initialURL: URL) {
            self.initialURL = initialURL
            super.init()
        }

        func load(_ url: URL, in webView: WKWebView) {
            errorView?.isHidden = true
            loadingView?.startAnimating()
            importSharedCookies(for: url, into: webView) {
                //webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
                var request = URLRequest(
                    url: url,
                    cachePolicy: .useProtocolCachePolicy,
                    timeoutInterval: 30
                )
                request.setValue("ios", forHTTPHeaderField: "X-SamVitals-App")
                request.setValue("ipad", forHTTPHeaderField: "X-SamVitals-Device")
                webView.load(request)
            }
        }

        @objc func refresh() {
            webView?.reload()
        }

        @objc func retry() {
            guard let webView else { return }
            load(initialURL, in: webView)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
            loadingView?.startAnimating()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            webView.scrollView.refreshControl?.endRefreshing()
            loadingView?.stopAnimating()
            exportCookies(from: webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
            handle(error, in: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
            handle(error, in: webView)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let destination = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            let isWebLink = destination.scheme == "http" || destination.scheme == "https"
            let isAllowedHost = destination.host == allowedHost

            if isWebLink && isAllowedHost {
                if navigationAction.targetFrame == nil {
                    webView.load(navigationAction.request)
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }
                return
            }

            UIApplication.shared.open(destination)
            decisionHandler(.cancel)
        }

        private func handle(_ error: Error, in webView: WKWebView) {
            webView.scrollView.refreshControl?.endRefreshing()

            let nsError = error as NSError
            guard nsError.code != NSURLErrorCancelled else { return }

            loadingView?.stopAnimating()

            if nsError.domain == NSURLErrorDomain {
                errorView?.show(
                    message: "Revisa tu conexión a internet e inténtalo de nuevo."
                )
            } else {
                errorView?.show(
                    message: "Ocurrió un problema al cargar el contenido."
                )
            }
        }

        private func importSharedCookies(for url: URL, into webView: WKWebView, completion: @escaping () -> Void) {
            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
            guard !cookies.isEmpty else {
                completion()
                return
            }

            let group = DispatchGroup()
            for cookie in cookies {
                group.enter()
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    group.leave()
                }
            }
            group.notify(queue: .main, execute: completion)
        }

        private func exportCookies(from webView: WKWebView) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                cookies.forEach(HTTPCookieStorage.shared.setCookie)
            }
        }
    }
}

private final class WebLoadingView: UIVisualEffectView {
    private let indicator = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()

    init() {
        super.init(effect: UIBlurEffect(style: .systemMaterial))
        layer.cornerRadius = 18
        clipsToBounds = true

        indicator.startAnimating()
        label.text = "Cargando SamVitals…"
        label.font = .preferredFont(forTextStyle: .subheadline)

        let stack = UIStackView(arrangedSubviews: [indicator, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        isHidden = false
        indicator.startAnimating()
    }

    func stopAnimating() {
        indicator.stopAnimating()
        isHidden = true
    }
}

private final class WebNetworkErrorView: UIView {
    let retryButton = UIButton(type: .system)
    private let messageLabel = UILabel()

    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        isHidden = true

        let imageView = UIImageView(
            image: UIImage(systemName: "wifi.exclamationmark")
        )
        imageView.tintColor = .secondaryLabel
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 34,
            weight: .medium
        )

        let titleLabel = UILabel()
        titleLabel.text = "No se pudo abrir SamVitals"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center

        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        retryButton.setTitle("Intentar de nuevo", for: .normal)
        retryButton.configuration = .filled()

        let stack = UIStackView(
            arrangedSubviews: [imageView, titleLabel, messageLabel, retryButton]
        )
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 460)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(message: String) {
        messageLabel.text = message
        isHidden = false
    }
}
