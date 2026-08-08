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
    private static let defaultHeaderColorHex = "#F9A000"

    private let checkoutUrl: URL
    private let returnUrlPrefix: String
    private let onOutcome: (HostedCheckoutOutcome) -> Void
    private let headerColor: UIColor
    private let headerColorIsLight: Bool

    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var didReportOutcome = false

    init(checkoutUrl: URL, returnUrlPrefix: String, headerColorHex: String?, onOutcome: @escaping (HostedCheckoutOutcome) -> Void) {
        self.checkoutUrl = checkoutUrl
        self.returnUrlPrefix = returnUrlPrefix
        self.onOutcome = onOutcome
        let resolvedColor = headerColorHex.flatMap(Self.color(fromHex:)) ?? Self.color(fromHex: Self.defaultHeaderColorHex)!
        self.headerColor = resolvedColor
        self.headerColorIsLight = Self.isColorLight(resolvedColor)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        headerColorIsLight ? .darkContent : .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        if let navigationBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = headerColor
            let tintColor: UIColor = headerColorIsLight ? .black : .white
            appearance.titleTextAttributes = [.foregroundColor: tintColor]
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.tintColor = tintColor
        }

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

    private static func color(fromHex hex: String) -> UIColor? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        guard hexString.count == 6, let rgbValue = UInt32(hexString, radix: 16) else {
            return nil
        }
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    private static func isColorLight(_ color: UIColor) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.5
    }

    private func updateBackButton() {
        let title = webView.canGoBack ? "Back" : "Close"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(backButtonTapped))
    }

    @objc private func backButtonTapped() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            confirmClose()
        }
    }

    private func confirmClose() {
        let alert = UIAlertController(
            title: "Cancel payment?",
            message: "Are you sure you want to leave? Your payment will not be completed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Stay", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "Leave", style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.reportOutcome(.closed)
                self.dismiss(animated: true)
            }
        )
        present(alert, animated: true)
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
