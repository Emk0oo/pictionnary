import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  MobileScannerController controller = MobileScannerController();
  bool hasScanned = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          hasScanned = true;
        });
        _showResultDialog(code);
      }
    }
  }

  void _showResultDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code scanné'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              Text('Code de la partie : $code'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner();
              },
              child: const Text('Scanner à nouveau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _joinGame(code);
              },
              child: const Text('Rejoindre'),
            ),
          ],
        );
      },
    );
  }

  void _joinGame(String gameCode) {
    // Navigation vers l'écran de jeu
    Navigator.pushReplacementNamed(
      context,
      '/game',
      arguments: {'gameCode': gameCode},
    );
  }

  void _resetScanner() {
    setState(() {
      hasScanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(controller: controller, onDetect: _handleBarcode),
                // Overlay avec instructions
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Placez le QR code dans le cadre pour rejoindre la partie',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Cadre de scan
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Scannez le QR code de la partie',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _resetScanner,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
