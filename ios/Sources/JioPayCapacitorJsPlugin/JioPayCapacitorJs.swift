import Foundation
import UIKit

enum JioPayCheckoutError: Error {
    case invalidCheckoutUrl
    case closedBeforeCompletion
}

@objc public class JioPayCapacitorJs: NSObject {
    func openHostedCheckout(
        checkoutUrl: String,
        returnUrlPrefix: String,
        headerColor: String?,
        presentingViewController: UIViewController,
        completion: @escaping (Result<(url: String, params: [String: String]), JioPayCheckoutError>) -> Void
    ) {
        guard let url = URL(string: checkoutUrl), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            completion(.failure(.invalidCheckoutUrl))
            return
        }

        let checkoutViewController = HostedCheckoutViewController(checkoutUrl: url, returnUrlPrefix: returnUrlPrefix, headerColorHex: headerColor) { outcome in
            switch outcome {
            case .landed(let landedUrl, let params):
                completion(.success((url: landedUrl, params: params)))
            case .closed:
                completion(.failure(.closedBeforeCompletion))
            }
        }

        let navigationController = UINavigationController(rootViewController: checkoutViewController)
        navigationController.modalPresentationStyle = .fullScreen
        presentingViewController.present(navigationController, animated: true)
    }
}
