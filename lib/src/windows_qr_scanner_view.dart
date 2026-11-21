import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'scanner_state.dart';
import 'windows_qr_scanner_controller.dart';

/// A widget that displays the live Windows camera preview and a scan overlay.
///
/// Reacts to [WindowsQrScannerController.stateNotifier] to render loading,
/// error, uninitialized, and active camera preview states.
class WindowsQrScannerView extends StatelessWidget {
  /// Creates a [WindowsQrScannerView] bound to [controller].
  ///
  /// [overlay] defaults to a centered corner-bracket viewfinder.
  /// [fit] controls how the camera preview is fitted within its bounds and
  /// defaults to [BoxFit.cover].
  const WindowsQrScannerView({
    super.key,
    required this.controller,
    this.overlay = const _DefaultQrOverlay(),
    this.fit = BoxFit.cover,
  });

  /// The controller managing the camera and scanning lifecycle.
  final WindowsQrScannerController controller;

  /// The widget layered on top of the camera preview.
  final Widget overlay;

  /// How the camera preview should be inscribed into the available space.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WindowsQrScannerState>(
      valueListenable: controller.stateNotifier,
      builder: (context, state, _) {
        if (state.status == WindowsQrScannerStatus.initializing) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == WindowsQrScannerStatus.error &&
            state.errorMessage != null) {
          return Center(
            child: Text(state.errorMessage!, textAlign: TextAlign.center),
          );
        }

        final cameraController = controller.cameraController;
        if (cameraController == null || !cameraController.value.isInitialized) {
          return const Center(
            child: Text('Camera is not ready. Call startScanning() first.'),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            _CameraPreviewView(controller: cameraController, fit: fit),
            overlay,
          ],
        );
      },
    );
  }
}

class _CameraPreviewView extends StatelessWidget {
  const _CameraPreviewView({required this.controller, required this.fit});

  final CameraController controller;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        final width = constraints.maxWidth;
        var height = constraints.maxHeight;

        if (previewSize != null) {
          final aspectRatio = previewSize.height / previewSize.width;
          height = width * aspectRatio;
        }

        return Center(
          child: ClipRect(
            child: FittedBox(
              fit: fit,
              child: SizedBox(
                width: width,
                height: height,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DefaultQrOverlay extends StatelessWidget {
  const _DefaultQrOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _QrScanOverlayPainter());
  }
}

class _QrScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final scanSize =
        (size.width < size.height ? size.width : size.height) * 0.85;
    final scanX = (size.width - scanSize) / 2;
    final scanY = (size.height - scanSize) / 2;
    const cornerLength = 30.0;

    canvas.drawLine(
      Offset(scanX, scanY),
      Offset(scanX + cornerLength, scanY),
      paint,
    );
    canvas.drawLine(
      Offset(scanX, scanY),
      Offset(scanX, scanY + cornerLength),
      paint,
    );

    canvas.drawLine(
      Offset(scanX + scanSize, scanY),
      Offset(scanX + scanSize - cornerLength, scanY),
      paint,
    );
    canvas.drawLine(
      Offset(scanX + scanSize, scanY),
      Offset(scanX + scanSize, scanY + cornerLength),
      paint,
    );

    canvas.drawLine(
      Offset(scanX, scanY + scanSize),
      Offset(scanX + cornerLength, scanY + scanSize),
      paint,
    );
    canvas.drawLine(
      Offset(scanX, scanY + scanSize),
      Offset(scanX, scanY + scanSize - cornerLength),
      paint,
    );

    canvas.drawLine(
      Offset(scanX + scanSize, scanY + scanSize),
      Offset(scanX + scanSize - cornerLength, scanY + scanSize),
      paint,
    );
    canvas.drawLine(
      Offset(scanX + scanSize, scanY + scanSize),
      Offset(scanX + scanSize, scanY + scanSize - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
