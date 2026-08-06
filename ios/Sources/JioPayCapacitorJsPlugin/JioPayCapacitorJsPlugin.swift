import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(JioPayCapacitorJsPlugin)
public class JioPayCapacitorJsPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "JioPayCapacitorJsPlugin"
    public let jsName = "JioPayCapacitorJs"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "openHostedCheckout", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = JioPayCapacitorJs()

    @objc func openHostedCheckout(_ call: CAPPluginCall) {
        guard let checkoutUrl = call.getString("checkoutUrl"), !checkoutUrl.isEmpty else {
            call.reject("Missing required option: checkoutUrl")
            return
        }
        guard let returnUrlPrefix = call.getString("returnUrlPrefix"), !returnUrlPrefix.isEmpty else {
            call.reject("Missing required option: returnUrlPrefix")
            return
        }
        guard let presentingViewController = self.bridge?.viewController else {
            call.reject("No active view controller to open checkout in")
            return
        }

        DispatchQueue.main.async {
            self.implementation.openHostedCheckout(
                checkoutUrl: checkoutUrl,
                returnUrlPrefix: returnUrlPrefix,
                presentingViewController: presentingViewController
            ) { result in
                switch result {
                case .success(let landed):
                    call.resolve(["url": landed.url, "params": landed.params])
                case .failure(.invalidCheckoutUrl):
                    call.reject("Invalid checkoutUrl")
                case .failure(.closedBeforeCompletion):
                    call.reject("Checkout closed before reaching the return URL")
                }
            }
        }
    }
}
