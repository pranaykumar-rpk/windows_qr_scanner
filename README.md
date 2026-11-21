# windows_qr_scanner

[![pub package](https://img.shields.io/pub/v/windows_qr_scanner.svg)](https://pub.dev/packages/windows_qr_scanner)

A production-ready Windows-only Flutter QR scanner package built exclusively for desktop applications. It provides high-performance background QR decoding via ZXing and `camera_windows`, without blocking the main UI thread.

## Features

- **Windows desktop support only**: Highly optimized for Windows environments.
- **Configurable frame throttling**: Adjust the frame capture interval to balance performance and SSD disk I/O.
- **Background Decoding**: Heavy ZXing decoding isolates prevent UI jank.
- **Memory Safe**: Avoids disk write pollution by strictly utilizing `getTemporaryDirectory` and disposing corrupted frames automatically.
- **Reusable Architecture**: Clean API with a dedicated `WindowsQrScannerController` and an overlay-ready `WindowsQrScannerView`.

## Install

Add `windows_qr_scanner` to your `pubspec.yaml`:

```yaml
dependencies:
  windows_qr_scanner: ^0.1.0
```

## Setup & Requirements

Since this plugin relies on Windows desktop constraints, you **must ensure the camera permissions and capabilities are configured**.
There are no additional `AndroidManifest.xml` or `Info.plist` files required, but your Flutter Windows runner must be intact.

## Usage

```dart
// 1. Initialize the controller
final controller = WindowsQrScannerController(
  // The delay between frame captures. 
  // For performance, 500ms is highly recommended to prevent I/O bottlenecking.
  scanInterval: const Duration(milliseconds: 500),
  stopOnFirstDetect: true,
);

// 2. Start scanning
await controller.startScanning(
  onQrDetected: (String code) {
    print('Detected code: $code');
  },
  onError: (Object error) {
    print('Scanner error: $error');
  },
);

// 3. Optional visual preview
WindowsQrScannerView(controller: controller);

// 4. Dispose when done
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

## Performance Notes
Due to limitations in the underlying `camera_windows` plugin (lack of image stream support), this package uses `takePicture()` to capture frames periodically. **A scan interval of 100ms or lower will cause extreme disk I/O overhead on your users' SSDs.** Stick to >=500ms for stable production deployments.

## Platform support

This package restricts capabilities to **Windows only**. Calling `startScanning` on unsupported platforms throws an `UnsupportedError`. Ensure you check `Platform.isWindows` before mounting the UI if your app is cross-platform.

## Example

See the [example](example/) folder for a complete runnable app demonstrating proper lifecycle and error handling.

## Author

Developed by **Pranay Kumar** ([@pranaykumar-rpk](https://github.com/pranaykumar-rpk)).

## License

MIT - see the [LICENSE](LICENSE) file.
