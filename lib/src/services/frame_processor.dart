import 'dart:io';

import 'package:flutter/foundation.dart';

import 'zxing_qr_decoder.dart';

/// Reads captured image files and decodes QR codes in a background isolate.
class FrameProcessor {
  /// Creates a [FrameProcessor].
  const FrameProcessor();

  /// Reads the image at [filePath] and attempts to decode a QR code off the
  /// main UI thread using [compute].
  Future<String?> processFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return compute(_decodeInIsolate, _DecodePayload(bytes));
  }

  static String? _decodeInIsolate(_DecodePayload payload) {
    const decoder = ZxingQrDecoder();
    return decoder.decode(payload.bytes);
  }
}

class _DecodePayload {
  const _DecodePayload(this.bytes);

  final Uint8List bytes;
}
