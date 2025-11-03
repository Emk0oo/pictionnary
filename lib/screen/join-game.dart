import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/global_data.dart' as global;

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  MobileScannerController controller = MobileScannerController();
  bool hasScanned = false;
  bool isJoining = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          hasScanned = true;
        });
        _joinGameDirectly(code);
      }
    }
  }

  Future<void> _joinGameDirectly(String gameCode) async {
    setState(() {
      isJoining = true;
    });

    try {
      print('=== VÉRIFICATION SESSION $gameCode ===');

      // Vérifier que la session existe
      final checkResponse = await http.get(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$gameCode',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      print('Status vérification: ${checkResponse.statusCode}');
      print('Réponse: ${checkResponse.body}');

      if (checkResponse.statusCode == 200) {
        final sessionData = jsonDecode(checkResponse.body);

        // Vérifier les places disponibles dans chaque équipe
        bool redTeamFull =
            sessionData['red_player_1'] != null &&
            sessionData['red_player_2'] != null;
        bool blueTeamFull =
            sessionData['blue_player_1'] != null &&
            sessionData['blue_player_2'] != null;

        if (redTeamFull && blueTeamFull) {
          _showErrorDialog('Cette partie est complète (4/4 joueurs)');
          return;
        }

        // Afficher le dialogue de sélection d'équipe
        _showTeamSelectionDialog(gameCode, redTeamFull, blueTeamFull);
      } else {
        _showErrorDialog(
          'Cette partie n\'existe pas ou n\'est plus disponible',
        );
      }
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      _showErrorDialog(
        'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    } finally {
      setState(() {
        isJoining = false;
      });
    }
  }

  void _showTeamSelectionDialog(
    String gameCode,
    bool redTeamFull,
    bool blueTeamFull,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rejoindre la partie $gameCode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisissez votre équipe :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Bouton équipe rouge
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      redTeamFull
                          ? null
                          : () {
                            Navigator.of(context).pop();
                            _joinTeam(gameCode, 'red');
                          },
                  icon: Icon(
                    redTeamFull ? Icons.group_off : Icons.group,
                    color: redTeamFull ? Colors.grey : Colors.white,
                  ),
                  label: Text(
                    redTeamFull ? 'Équipe Rouge (Complète)' : 'Équipe Rouge',
                    style: TextStyle(
                      color: redTeamFull ? Colors.grey : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        redTeamFull ? Colors.grey[300] : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bouton équipe bleue
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      blueTeamFull
                          ? null
                          : () {
                            Navigator.of(context).pop();
                            _joinTeam(gameCode, 'blue');
                          },
                  icon: Icon(
                    blueTeamFull ? Icons.group_off : Icons.group,
                    color: blueTeamFull ? Colors.grey : Colors.white,
                  ),
                  label: Text(
                    blueTeamFull ? 'Équipe Bleue (Complète)' : 'Équipe Bleue',
                    style: TextStyle(
                      color: blueTeamFull ? Colors.grey : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        blueTeamFull ? Colors.grey[300] : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner();
              },
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinTeam(String gameCode, String team) async {
    // Afficher un loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connexion à la partie...'),
            ],
          ),
        );
      },
    );

    try {
      print('=== JOIN ÉQUIPE $team POUR SESSION $gameCode ===');

      final joinResponse = await http.post(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$gameCode/join',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${global.token}',
        },
        body: jsonEncode({'color': team}),
      );

      print('Status join: ${joinResponse.statusCode}');
      print('Réponse join: ${joinResponse.body}');

      // Fermer le dialogue de loading
      Navigator.of(context).pop();

      if (joinResponse.statusCode == 200 || joinResponse.statusCode == 201) {
        // Succès ! Naviguer vers la waiting room
        Navigator.pushReplacementNamed(
          context,
          '/join-waiting-room',
          arguments: {
            'gameSessionId': gameCode,
            'team': team,
            'hasJoined': true,
          },
        );
      } else {
        _showErrorDialog(
          'Impossible de rejoindre l\'équipe ${team == 'red' ? 'rouge' : 'bleue'}. Erreur: ${joinResponse.statusCode}',
        );
      }
    } catch (e) {
      // Fermer le dialogue de loading
      Navigator.of(context).pop();
      print('Erreur join team: $e');
      _showErrorDialog('Erreur lors de la connexion: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner();
              },
              child: const Text('Réessayer'),
            ),
          ],
        );
      },
    );
  }

  void _resetScanner() {
    setState(() {
      hasScanned = false;
      isJoining = false;
    });
  }

  // Fonction pour tester avec un QR code simulé
  void _testQRCode() {
    if (hasScanned) return;
    setState(() {
      hasScanned = true;
    });
    _joinGameDirectly("1652");
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
          // Bouton de test pour simuler un QR code
          IconButton(
            onPressed: _testQRCode,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Test QR Code (1233)',
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

                // Overlay de loading si en cours de traitement
                if (isJoining)
                  Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Vérification de la partie...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Overlay avec instructions
                if (!isJoining)
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
                if (!isJoining)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isJoining ? null : _resetScanner,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réinitialiser'),
                      ),
                      // Bouton de test visible
                      ElevatedButton.icon(
                        onPressed: isJoining ? null : _testQRCode,
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Test (1233)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ],
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
