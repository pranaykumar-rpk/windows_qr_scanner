import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'scanner_state.dart';
import 'services/windows_qr_scanner_service.dart';

/// Controller for managing the lifecycle and state of the Windows QR Scanner.
///
/// Use this controller to start/stop scanning operations and listen to the
/// [stateNotifier] for UI updates.
class WindowsQrScannerController extends ChangeNotifier {
  /// Creates a new [WindowsQrScannerController].
  ///
  /// [scanInterval] defines how frequently the camera frame is captured
  /// and processed. For performance reasons, a minimum of 500ms is recommended.
  /// defaults to `Duration(milliseconds: 500)`.
  ///
  /// [stopOnFirstDetect] specifies if the scanner should automatically stop
  /// capturing frames once a valid QR code is decoded. Defaults to `true`.
  WindowsQrScannerController({
    this.scanInterval = const Duration(milliseconds: 500),
    this.stopOnFirstDetect = true,
  }) : _service = WindowsQrScannerService(
          scanInterval: scanInterval,
          stopOnFirstDetect: stopOnFirstDetect,
        );

  /// How frequently a camera frame is captured and decoded.
  final Duration scanInterval;

  /// Whether scanning automatically stops after the first QR code is detected.
  final bool stopOnFirstDetect;
  final WindowsQrScannerService _service;

  /// Notifies listeners whenever the scanner's [WindowsQrScannerState] changes.
  final ValueNotifier<WindowsQrScannerState> stateNotifier =
      ValueNotifier<WindowsQrScannerState>(WindowsQrScannerState.idle);

  bool _isDisposed = false;

  /// The current [WindowsQrScannerState] of the scanner.
  WindowsQrScannerState get state => stateNotifier.value;

  /// The underlying [CameraController], or `null` if not yet initialized.
  CameraController? get cameraController => _service.cameraController;

  /// Starts the camera and background scanning process.
  ///
  /// [onQrDetected] is called whenever a new QR code is successfully decoded.
  /// [onError] is an optional callback to handle camera or file system exceptions.
  Future<void> startScanning({
    required ValueChanged<String> onQrDetected,
    void Function(Object error)? onError,
  }) async {
    _ensureNotDisposed();

    await _service.start(
      onQrDetected: onQrDetected,
      onStateChanged: _onStateChanged,
      onError: (error, _) => onError?.call(error),
    );
    notifyListeners();
  }

  /// Stops the camera and background scanning process.
  Future<void> stopScanning() async {
    _ensureNotDisposed();
    await _service.stop();
    notifyListeners();
  }

  void _onStateChanged(WindowsQrScannerState state) {
    if (_isDisposed) {
      return;
    }
    stateNotifier.value = state;
    notifyListeners();
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('WindowsQrScannerController is already disposed.');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    unawaited(_service.dispose());
    stateNotifier.dispose();
    super.dispose();
  }
}
