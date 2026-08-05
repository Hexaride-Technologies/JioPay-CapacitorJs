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
        CAPPluginMethod(name: "echo", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = JioPayCapacitorJs()

    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": implementation.echo(value)
        ])
    }
}
