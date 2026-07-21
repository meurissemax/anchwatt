import Cocoa
import FlutterMacOS

// Thin bridge over NSPasteboard so Dart can drop a rendered PNG onto the general
// pasteboard as an image, ready to be pasted straight into Slack (Cmd+V). Bytes
// arrive from Dart as a Uint8List, surfaced here as FlutterStandardTypedData.
final class ClipboardChannel: NSObject {
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "copyPng":
      guard let typed = call.arguments as? FlutterStandardTypedData,
            let image = NSImage(data: typed.data) else {
        result(
          FlutterError(
            code: "invalid_image",
            message: "Expected PNG bytes decodable as an NSImage",
            details: nil
          )
        )
        return
      }
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      let written = pasteboard.writeObjects([image])
      if written {
        result(nil)
      } else {
        result(
          FlutterError(
            code: "clipboard_write_failed",
            message: "NSPasteboard rejected the image",
            details: nil
          )
        )
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
