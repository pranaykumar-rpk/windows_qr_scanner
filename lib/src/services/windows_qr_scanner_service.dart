import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../scanner_state.dart';
import 'frame_processor.dart';
import 'windows_camera_manager.dart';

typedef OnQrDetected = void Function(String code);
typedef OnStateChanged = void Function(WindowsQrScannerState state);
typedef OnError = void Function(Object error, StackTrace? stackTrace);

class WindowsQrScannerService {
  WindowsQrScannerService({
    required Duration scanInterval,
    required bool stopOnFirstDetect,
    WindowsCameraManager? cameraManager,
    FrameProcessor? frameProcessor,
  })  : _scanInterval = scanInterval,
        _stopOnFirstDetect = stopOnFirstDetect,
        _cameraManager = cameraManager ?? WindowsCameraManager(),
        _frameProcessor = frameProcessor ?? const FrameProcessor();

  final Duration _scanInterval;
  final bool _stopOnFirstDetect;
  final WindowsCameraManager _cameraManager;
  final FrameProcessor _frameProcessor;

  Timer? _timer;
  bool _isProcessing = false;
  bool _isScanning = false;
  String? _lastDetectedCode;

  OnStateChanged? _onStateChanged;
  OnQrDetected? _onQrDetected;
  OnError? _onError;

  CameraController? get cameraController => _cameraManager.controller;
  bool get isInitialized => _cameraManager.isInitialized;

  Future<void> start({
    required OnQrDetected onQrDetected,
    required OnStateChanged onStateChanged,
    OnError? onError,
  }) async {
    _assertWindows();
    _onQrDetected = onQrDetected;
    _onStateChanged = onStateChanged;
    _onError = onError;
    _emit(
      const WindowsQrScannerState(status: WindowsQrScannerStatus.initializing),
    );

    try {
      if (!isInitialized) {
        await _cameraManager.initialize();
      }
      _isScanning = true;
      _emit(const WindowsQrScannerState(status: WindowsQrScannerStatus.ready));
      _startTimer();
      _emit(
        const WindowsQrScannerState(status: WindowsQrScannerStatus.scanning),
      );
    } catch (error) {
      _isScanning = false;
      _emit(
        WindowsQrScannerState(
          status: WindowsQrScannerStatus.error,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _isScanning = false;
    _isProcessing = false;
    _emit(const WindowsQrScannerState(status: WindowsQrScannerStatus.stopped));
  }

  Future<void> dispose() async {
    await stop();
    await _cameraManager.dispose();
    _emit(const WindowsQrScannerState(status: WindowsQrScannerStatus.disposed));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_scanInterval, (_) => _captureAndProcess());
  }

  Future<void> _captureAndProcess() async {
    if (!_isScanning || _isProcessing) {
      return;
    }

    final cameraController = _cameraManager.controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    _isProcessing = true;
    XFile? frame;

    try {
      frame = await _cameraManager.captureFrame();

      // Save images to getTemporaryDirectory() instead of root
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path,
          'qr_frame_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Move file to explicit temp directory
      try {
        await File(frame.path).rename(targetPath);
      } on FileSystemException {
        // Fallback to copy/delete if rename fails across volumes
        await File(frame.path).copy(targetPath);
        unawaited(_deleteTempFile(frame.path));
      }

      final code = await _frameProcessor.processFile(targetPath);

      unawaited(_deleteTempFile(targetPath));

      if (code == null || code.isEmpty) {
        return;
      }

      if (_lastDetectedCode == code) {
        return;
      }

      _lastDetectedCode = code;
      _onQrDetected?.call(code);

      if (_stopOnFirstDetect) {
        await stop();
      }
    } on FileSystemException catch (fsError, stackTrace) {
      _onError?.call(fsError, stackTrace);
    } on CameraException catch (cameraError, stackTrace) {
      _onError?.call(cameraError, stackTrace);
    } catch (e, stackTrace) {
      _onError?.call(e, stackTrace);
    } finally {
      if (frame != null) {
        unawaited(_deleteTempFile(frame.path));
      }
      _isProcessing = false;
    }
  }

  Future<void> _deleteTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (e, stackTrace) {
      _onError?.call(e, stackTrace);
    } catch (_) {
      // Safely ignore standard cleanup failures.
    }
  }

  void _emit(WindowsQrScannerState state) {
    _onStateChanged?.call(state);
  }

  void _assertWindows() {
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'windows_qr_scanner only supports Windows desktop.',
      );
    }
  }
}
