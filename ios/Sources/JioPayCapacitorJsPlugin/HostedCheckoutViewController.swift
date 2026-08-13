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
final class HostedCheckoutViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate {
    private static let defaultHeaderColorHex = "#F9A000"

    // WKWebView zooms in on its own whenever a focused <input> has an
    // effective font-size under ~16px, regardless of what the remote
    // checkout page's viewport meta tag says. Forcing the tag's content
    // (and separately locking the scroll view's zoom scale below) covers
    // pages that omit the tag entirely as well as ones that allow scaling.
    private static let viewportFixScript = """
    (function() {
        var content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            (document.head || document.documentElement).appendChild(meta);
        }
        meta.setAttribute('content', content);
    })();
    """

    private let checkoutUrl: URL
    private let returnUrlPrefix: String
    private let onOutcome: (HostedCheckoutOutcome) -> Void
    private let headerColor: UIColor
    private let headerColorIsLight: Bool

    private let webView = HostedCheckoutViewController.makeWebView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let closeButton = UIButton(type: .system)
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

        view.backgroundColor = headerColor
        navigationController?.setNavigationBarHidden(true, animated: false)

        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        configureCloseButton()
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),
        ])

        webView.load(URLRequest(url: checkoutUrl))
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        nil
    }

    private static func makeWebView() -> WKWebView {
        let userScript = WKUserScript(source: viewportFixScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController

        return WKWebView(frame: .zero, configuration: configuration)
    }

    private func configureCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        closeButton.tintColor = headerColorIsLight ? .black : .white
        closeButton.backgroundColor = headerColor.withAlphaComponent(0.9)
        closeButton.layer.cornerRadius = 18
        closeButton.layer.masksToBounds = true
        closeButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
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

    // Never calls webView.goBack() — letting the close button navigate the
    // page can trigger unexpected behavior mid-checkout (e.g. re-submitting
    // a form, landing on a stale bank/ACS step). It always shows the cancel
    // confirmation instead.
    @objc private func backButtonTapped() {
        confirmClose()
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
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
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
