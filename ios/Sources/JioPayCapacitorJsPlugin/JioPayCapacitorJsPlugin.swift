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
    public let pluginMethods: [CAPPluginMethod] = []
    private let implementation = JioPayCapacitorJs()
}
