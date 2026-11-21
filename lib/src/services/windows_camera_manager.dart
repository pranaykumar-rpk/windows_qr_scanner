import 'dart:io';

import 'package:camera/camera.dart';

/// Manages the Windows camera lifecycle, selection, and frame capture.
class WindowsCameraManager {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];

  /// The active [CameraController], or `null` if not initialized.
  CameraController? get controller => _controller;

  /// Unmodifiable list of cameras discovered on the device.
  List<CameraDescription> get cameras => List.unmodifiable(_cameras);

  /// Whether the camera controller is currently initialized.
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Discovers available cameras and initializes the selected camera.
  ///
  /// Throws an [UnsupportedError] on non-Windows platforms and a [StateError]
  /// if no cameras are found.
  Future<void> initialize({
    CameraDescription? preferredCamera,
    ResolutionPreset resolutionPreset = ResolutionPreset.low,
  }) async {
    _assertWindows();
    await dispose();

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw StateError('No camera found on this Windows device.');
    }

    final selectedCamera = preferredCamera ?? _pickDefaultCamera(_cameras);

    final controller = CameraController(
      selectedCamera,
      resolutionPreset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();
    _controller = controller;
  }

  /// Captures a single still frame from the initialized camera.
  Future<XFile> captureFrame() async {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      throw StateError('Camera is not initialized.');
    }
    return cameraController.takePicture();
  }

  /// Disposes the active [CameraController], if any.
  Future<void> dispose() async {
    final cameraController = _controller;
    _controller = null;
    if (cameraController != null) {
      await cameraController.dispose();
    }
  }

  CameraDescription _pickDefaultCamera(List<CameraDescription> cameras) {
    const keywords = ['laptop', 'webcam', 'built-in', 'integrated', 'internal'];
    for (final camera in cameras) {
      final name = camera.name.toLowerCase();
      if (keywords.any(name.contains)) {
        return camera;
      }
    }
    return cameras.first;
  }

  void _assertWindows() {
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'windows_qr_scanner only supports Windows desktop.',
      );
    }
  }
}
