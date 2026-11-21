enum WindowsQrScannerStatus {
  idle,
  initializing,
  ready,
  scanning,
  stopped,
  disposed,
  error,
}

class WindowsQrScannerState {
  const WindowsQrScannerState({required this.status, this.errorMessage});

  final WindowsQrScannerStatus status;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  WindowsQrScannerState copyWith({
    WindowsQrScannerStatus? status,
    String? errorMessage,
  }) {
    return WindowsQrScannerState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  static const idle = WindowsQrScannerState(
    status: WindowsQrScannerStatus.idle,
  );
}
