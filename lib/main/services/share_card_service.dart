import 'dart:io';

import 'package:flutter/services.dart';

// External I/O for the shareable stats card: it drops the rendered PNG in the
// system temp directory (disposable — the OS reaps it, and it never lands in a
// user folder) and hands the same bytes to the native pasteboard bridge so the
// card can be pasted straight into Slack. The capture/render itself is a UI
// concern and lives in the widget layer; this service only persists and copies.
class ShareCardService {
  /* Static variables */

  static const String _channelName = 'com.anchwatt/clipboard';
  static const String _tempFileName = 'anchwatt-stats-card.png';

  /* Variables */

  final MethodChannel _channel = const MethodChannel(_channelName);

  /* Methods */

  // Writes (overwriting) the PNG to a stable path in the system temp directory
  // and returns the file. The name is fixed on purpose: successive shares reuse
  // the same throwaway file rather than piling up.
  Future<File> writeTempPng(Uint8List bytes) async {
    final File file = File('${Directory.systemTemp.path}/$_tempFileName');

    return file.writeAsBytes(bytes, flush: true);
  }

  // Places the PNG on the general pasteboard as an image. Throws on a native
  // decode/write failure so the caller can surface an error state.
  Future<void> copyToClipboard(Uint8List bytes) async {
    await _channel.invokeMethod<void>('copyPng', bytes);
  }
}
