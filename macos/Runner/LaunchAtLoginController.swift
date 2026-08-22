import Cocoa
import FlutterMacOS
import ServiceManagement

// SMAppService requires macOS 13 — on macOS 12 the feature degrades: the
// entry is reported as disabled and enabling it fails with `unsupported`,
// which the Dart side already surfaces as a launch-at-login error state.
final class LaunchAtLoginController: NSObject {
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isEnabled":
      if #available(macOS 13.0, *) {
        result(SMAppService.mainApp.status == .enabled)
      } else {
        result(false)
      }
    case "setEnabled":
      guard let enabled = call.arguments as? Bool else {
        result(FlutterError(
          code: "invalid_argument",
          message: "setEnabled expects a Bool argument",
          details: nil
        ))
        return
      }
      guard #available(macOS 13.0, *) else {
        result(FlutterError(
          code: "unsupported",
          message: "Launch at login requires macOS 13 or later",
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
