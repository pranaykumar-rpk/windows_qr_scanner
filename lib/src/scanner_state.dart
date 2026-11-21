/// Represents the lifecycle status of the Windows QR scanner.
enum WindowsQrScannerStatus {
  /// The scanner has not been started yet.
  idle,

  /// The camera and scanner resources are currently initializing.
  initializing,

  /// The camera is initialized and ready to begin scanning.
  ready,

  /// The scanner is actively capturing and decoding camera frames.
  scanning,

  /// Scanning has been paused or stopped.
  stopped,

  /// The scanner and its underlying camera resources have been disposed.
  disposed,

  /// An error occurred during initialization or scanning.
  error,
}

/// Immutable state snapshot for [WindowsQrScannerController].
class WindowsQrScannerState {
  /// Creates a [WindowsQrScannerState] with the given [status] and optional
  /// [errorMessage].
  const WindowsQrScannerState({required this.status, this.errorMessage});

  /// The current lifecycle status of the scanner.
  final WindowsQrScannerStatus status;

  /// A human-readable description of the error when [status] is
  /// [WindowsQrScannerStatus.error], or `null` otherwise.
  final String? errorMessage;

  /// Whether this state carries an error message.
  bool get hasError => errorMessage != null;

  /// Returns a copy of this state with the given fields replaced.
  WindowsQrScannerState copyWith({
    WindowsQrScannerStatus? status,
    String? errorMessage,
  }) {
    return WindowsQrScannerState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  /// The initial idle state before scanning is started.
  static const idle = WindowsQrScannerState(
    status: WindowsQrScannerStatus.idle,
  );
}
