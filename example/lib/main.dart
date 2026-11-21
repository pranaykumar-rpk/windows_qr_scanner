import 'package:flutter/material.dart';
import 'package:windows_qr_scanner/windows_qr_scanner.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Windows QR Scanner Example',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const ScannerHomePage(),
    );
  }
}

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({super.key});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  late final WindowsQrScannerController _controller;
  String _lastDetected = 'No QR detected yet';
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _controller = WindowsQrScannerController(
      scanInterval: const Duration(milliseconds: 500),
      stopOnFirstDetect: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _lastDetected = 'Scanning...';
    });

    try {
      await _controller.startScanning(
        onQrDetected: (code) {
          if (!mounted) {
            return;
          }
          setState(() {
            _lastDetected = code;
            _isScanning = false;
          });
        },
        onError: (error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isScanning = false;
            _lastDetected = 'Scanner Error: $error';
          });
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isScanning = false;
        _lastDetected = 'Error starting scanner: $error';
      });
    }
  }

  Future<void> _stopScan() async {
    await _controller.stopScanning();
    if (!mounted) {
      return;
    }
    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Windows QR Scanner Example')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: WindowsQrScannerView(controller: _controller),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _lastDetected,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _isScanning ? null : _startScan,
                    child: const Text('Start Scanning'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isScanning ? _stopScan : null,
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
