import Flutter
import UIKit

public class IUpdaterPlugin: NSObject, FlutterPlugin {
    private enum Method {
      static let getAppVersion = "getAppVersion"
      static let appId = "appId"
      static let openStore = "openStore"
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "i_updater", binaryMessenger: registrar.messenger())
    let instance = IUpdaterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    print("IUpdater: Plugin registered on iOS")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("IUpdater: iOS method called: \(call.method)")
    
    switch call.method {
    case Method.getAppVersion:
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
      print("IUpdater: iOS app version: \(version)")
      result(version)
      
    case Method.appId:
      let bundleId = Bundle.main.bundleIdentifier ?? ""
      print("IUpdater: iOS bundle ID: \(bundleId)")
      result(bundleId)
      
    case Method.openStore:
            if let arguments = call.arguments as? [String: Any],
               let urlString = arguments["url"] as? String {
               print("IUpdater: Opening iOS store URL: \(urlString)")
               if let url = URL(string: urlString) {
                   if UIApplication.shared.canOpenURL(url) {
                       UIApplication.shared.open(url, options: [:], completionHandler: { success in
                           print("IUpdater: URL open result: \(success)")
                           result(nil)
                       })
                   } else {
                       print("IUpdater: Cannot open URL: \(urlString)")
                       result(FlutterError(code: "cannot_open_url", message: "Cannot open URL: \(urlString)", details: nil))
                   }
               } else {
                   print("IUpdater: Invalid URL: \(urlString)")
                   result(FlutterError(code: "invalid_url", message: "Invalid URL format", details: nil))
               }
            } else {
                print("IUpdater: Missing URL argument")
                result(FlutterError(code: "invalid_arguments", message: "URL argument is missing or invalid", details: nil))
            }  
    default:
      print("IUpdater: Method not implemented: \(call.method)")
      result(FlutterMethodNotImplemented)
    }
  }
}
