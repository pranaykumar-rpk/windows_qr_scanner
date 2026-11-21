import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Decodes QR codes from raw image bytes using `zxing2` and `image`.
class ZxingQrDecoder {
  /// Creates a [ZxingQrDecoder].
  const ZxingQrDecoder();

  /// Attempts to decode a QR code from [imageBytes].
  ///
  /// Uses a multi-pass strategy (center-cropped and full-frame, downscaled to
  /// at most 800px, with an optional contrast-enhanced fallback) to improve
  /// detection reliability. Returns `null` if no QR code is found.
  String? decode(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      return null;
    }

    final reader = QRCodeReader();
    Result? result;
    final minDimension =
        image.width < image.height ? image.width : image.height;
    const cropRatios = <double>[0.75, 1.0];

    for (final ratio in cropRatios) {
      img.Image processedImage;
      if (ratio >= 1.0) {
        processedImage = image;
      } else {
        final cropSize = minDimension * ratio;
        final cropX = (image.width - cropSize) / 2;
        final cropY = (image.height - cropSize) / 2;
        processedImage = img.copyCrop(
          image,
          x: cropX.round(),
          y: cropY.round(),
          width: cropSize.round(),
          height: cropSize.round(),
        );
      }

      if (processedImage.width > 800 || processedImage.height > 800) {
        const targetSize = 800;
        final scaleFactor = targetSize /
            (processedImage.width > processedImage.height
                ? processedImage.width
                : processedImage.height);
        processedImage = img.copyResize(
          processedImage,
          width: (processedImage.width * scaleFactor).round(),
          height: (processedImage.height * scaleFactor).round(),
          interpolation: img.Interpolation.linear,
        );
      }

      result = _tryDecode(reader, processedImage);
      if (result != null && result.text.isNotEmpty) {
        return result.text;
      }

      final enhanced = img.adjustColor(processedImage, contrast: 1.3);
      result = _tryDecode(reader, enhanced);
      if (result != null && result.text.isNotEmpty) {
        return result.text;
      }
    }

    return null;
  }

  Result? _tryDecode(QRCodeReader reader, img.Image image) {
    try {
      final convertedImage = image.convert(numChannels: 4);
      final bytes = convertedImage.getBytes(order: img.ChannelOrder.abgr);
      final int32List = bytes.buffer.asInt32List();
      final source = RGBLuminanceSource(image.width, image.height, int32List);

      try {
        return reader.decode(BinaryBitmap(GlobalHistogramBinarizer(source)));
      } catch (_) {
        return reader.decode(BinaryBitmap(HybridBinarizer(source)));
      }
    } catch (_) {
      return null;
    }
  }
}
