import UIKit
import WebKit

enum HostedCheckoutOutcome {
    case landed(url: String, params: [String: String])
    case closed
}

/// Hosts JioPay's checkout page in an embedded WKWebView so navigation can be
/// intercepted: landing on a URL starting with returnUrlPrefix means the
/// gateway flow is done, and any non-http(s) URL (upi://, gpay://, etc.) is
/// handed off via UIApplication.open so installed UPI apps still get invoked
/// the way they would in a real browser.
final class HostedCheckoutViewController: UIViewController, WKNavigationDelegate {
    private let checkoutUrl: URL
    private let returnUrlPrefix: String
    private let onOutcome: (HostedCheckoutOutcome) -> Void

    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var didReportOutcome = false

    init(checkoutUrl: URL, returnUrlPrefix: String, onOutcome: @escaping (HostedCheckoutOutcome) -> Void) {
        self.checkoutUrl = checkoutUrl
        self.returnUrlPrefix = returnUrlPrefix
        self.onOutcome = onOutcome
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        updateBackButton()
        webView.load(URLRequest(url: checkoutUrl))
    }

    private func updateBackButton() {
        let title = webView.canGoBack ? "Back" : "Close"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(backButtonTapped))
    }

    @objc private func backButtonTapped() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            reportOutcome(.closed)
            dismiss(animated: true)
        }
    }

    private func reportOutcome(_ outcome: HostedCheckoutOutcome) {
        guard !didReportOutcome else { return }
        didReportOutcome = true
        onOutcome(outcome)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString
        if urlString.hasPrefix(returnUrlPrefix) {
            decisionHandler(.cancel)
            let params = parseQueryParams(from: url)
            reportOutcome(.landed(url: urlString, params: params))
            dismiss(animated: true)
            return
        }

        if url.scheme != "http" && url.scheme != "https" {
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        updateBackButton()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        updateBackButton()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        updateBackButton()
    }

    private func parseQueryParams(from url: URL) -> [String: String] {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return [:]
        }
        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value ?? ""
        }
        return params
    }
}
