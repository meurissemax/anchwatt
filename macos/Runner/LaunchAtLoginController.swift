import Cocoa
import FlutterMacOS
import ServiceManagement

final class LaunchAtLoginController: NSObject {
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isEnabled":
      result(SMAppService.mainApp.status == .enabled)
    case "setEnabled":
      guard let enabled = call.arguments as? Bool else {
        result(FlutterError(
          code: "invalid_argument",
          message: "setEnabled expects a Bool argument",
          details: nil
        ))
        return
      }
      do {
        if enabled {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
        result(nil)
      } catch {
        result(FlutterError(
          code: "sm_app_service_failed",
          message: error.localizedDescription,
          details: "\(error)"
        ))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
