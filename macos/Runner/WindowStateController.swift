import Cocoa
import FlutterMacOS

// Thin bridge over BackgroundModeController so Dart can:
//   - ask whether the main window is currently hidden into the status bar
//     (used by the notification dispatcher to gate level-up notifications),
//   - request a restore from the status bar (used by the notification tap
//     handler so a click brings the window back to the foreground).
final class WindowStateController: NSObject {
  private weak var backgroundModeController: BackgroundModeController?

  init(backgroundModeController: BackgroundModeController) {
    self.backgroundModeController = backgroundModeController
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isWindowHidden":
      result(backgroundModeController?.isHidden ?? false)
    case "showWindow":
      backgroundModeController?.exitBackgroundMode()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
