import 'dart:io';

import 'package:camera/camera.dart';

class WindowsCameraManager {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => List.unmodifiable(_cameras);
  bool get isInitialized => _controller?.value.isInitialized ?? false;

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

  Future<XFile> captureFrame() async {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      throw StateError('Camera is not initialized.');
    }
    return cameraController.takePicture();
  }

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
