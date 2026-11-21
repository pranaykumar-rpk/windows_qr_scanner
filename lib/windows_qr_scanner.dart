/// A Windows-only QR code scanner package for Flutter desktop applications.
///
/// Provides [WindowsQrScannerController] for managing camera lifecycle and
/// scanning state, [WindowsQrScannerView] for rendering the live camera
/// preview with a customizable overlay, and [WindowsQrScannerState] /
/// [WindowsQrScannerStatus] for observing scanner status.
library;

export 'src/scanner_state.dart';
export 'src/windows_qr_scanner_controller.dart';
export 'src/windows_qr_scanner_view.dart';
