import 'dart:io';

import 'package:flutter/foundation.dart';

import 'zxing_qr_decoder.dart';

class FrameProcessor {
  const FrameProcessor();

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
