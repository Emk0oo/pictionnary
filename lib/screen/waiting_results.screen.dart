import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../data/global_data.dart' as global;

class WaitingResultsScreen extends StatefulWidget {
  const WaitingResultsScreen({super.key});

  @override
  State<WaitingResultsScreen> createState() => _WaitingResultsScreenState();
}

class _WaitingResultsScreenState extends State<WaitingResultsScreen> {
  String? _gameSessionId;
  Timer? _pollingTimer;
  bool _isLoadingResults = false;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 600; // 30 minutes (600 * 3 seconds)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _gameSessionId = args['gameSessionId'];
        _startPolling();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Vérification immédiate
    _checkGameStatus();

    // Puis toutes les 5 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkGameStatus();
    });
  }

  Future<void> _checkGameStatus() async {
    if (_gameSessionId == null || _isLoadingResults) return;

    _pollingAttempts++;

    debugPrint('=== POLLING STATUS (Tentative $_pollingAttempts/$_maxPollingAttempts) ===');
    debugPrint('Game Session ID: $_gameSessionId');
    debugPrint('Is Loading Results: $_isLoadingResults');

    // Vérifier le timeout
    if (_pollingAttempts >= _maxPollingAttempts) {
      _pollingTimer?.cancel();
      _showTimeoutDialog();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/status',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      debugPrint('Status API Response Code: ${response.statusCode}');
      debugPrint('Status API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] as String?;

        debugPrint('>>> STATUT ACTUEL: $status <<<');

        if (status == 'finished') {
          // Le jeu est terminé, récupérer les résultats
          debugPrint('STATUT FINISHED → Récupération des résultats');
          _pollingTimer?.cancel();
          await _fetchAndShowResults();
        } else {
          debugPrint('STATUT $status → Continue d\'attendre');
        }
      }
    } catch (e) {
      // Continuer le polling même en cas d'erreur réseau temporaire
      debugPrint('Erreur polling status: $e');
    }
  }

  Future<void> _fetchAndShowResults() async {
    if (_gameSessionId == null || _isLoadingResults) return;

    debugPrint('=== RÉCUPÉRATION DES CHALLENGES ===');
    debugPrint('Game Session ID: $_gameSessionId');

    setState(() {
      _isLoadingResults = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/challenges',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      debugPrint('Challenges API Response Code: ${response.statusCode}');
      debugPrint('Challenges API Response: ${response.body}');

      if (response.statusCode == 200) {
        final challengesData = jsonDecode(response.body) as List;
        final challenges = challengesData
            .map((challenge) => challenge as Map<String, dynamic>)
            .toList();

        debugPrint('Nombre de challenges récupérés: ${challenges.length}');

        if (mounted) {
          debugPrint('Navigation vers /results');
          Navigator.pushReplacementNamed(
            context,
            '/results',
            arguments: {'challenges': challenges},
          );
        }
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des challenges: $e');
      setState(() {
        _isLoadingResults = false;
      });

      if (mounted) {
        _showErrorDialog('Impossible de charger les résultats: $e');
      }
    }
  }

  void _showTimeoutDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⏱️ Timeout'),
          content: const Text(
            'L\'attente a dépassé la limite de temps.\n'
            'Les autres joueurs n\'ont peut-être pas terminé.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Retour au menu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _pollingAttempts = 0;
                });
                _startPolling();
              },
              child: const Text('Continuer d\'attendre'),
            ),
          ],
        );
      },
    );
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
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Retour au menu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchAndShowResults();
              },
              child: const Text('Réessayer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('En attente...'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône animée
              const SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                ),
              ),

              const SizedBox(height: 40),

              // Titre
              const Text(
                '🎉 Félicitations !',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Message principal
              Text(
                'Vous avez terminé tous vos défis !',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Message d'attente
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 48,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'En attente des autres joueurs...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les résultats s\'afficheront dès que tout le monde aura terminé.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Bouton retour au menu (optionnel)
              OutlinedButton.icon(
                onPressed: () {
                  _pollingTimer?.cancel();
                  Navigator.pushReplacementNamed(context, '/');
                },
                icon: const Icon(Icons.home),
                label: const Text('Quitter et retourner au menu'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Indicateur de temps
              Text(
                'Vérification toutes les 5 secondes...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
