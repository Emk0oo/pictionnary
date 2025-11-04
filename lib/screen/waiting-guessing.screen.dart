import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../data/global_data.dart' as global;

class WaitingGuessingScreen extends StatefulWidget {
  const WaitingGuessingScreen({super.key});

  @override
  State<WaitingGuessingScreen> createState() => _WaitingGuessingScreenState();
}

class _WaitingGuessingScreenState extends State<WaitingGuessingScreen>
    with TickerProviderStateMixin {
  String? _gameSessionId;
  Timer? _statusTimer;
  String _gameStatus = 'drawing';
  int _nbDrawingsCompleted = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Animation pour le loading
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _gameSessionId = args['gameSessionId'];
        _startStatusChecking();
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startStatusChecking() {
    _checkGameStatus(); // Check immédiat
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkGameStatus();
    });
  }

  Future<void> _checkGameStatus() async {
    if (_gameSessionId == null || _isNavigating) return;

    try {
      debugPrint('=== VÉRIFICATION STATUS GUESSING ===');

      final response = await http.get(
        Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/status'),
        headers: {
          'Authorization': 'Bearer ${global.token}',
        },
      );

      debugPrint('Status response: ${response.statusCode}');
      debugPrint('Status body: ${response.body}');

      if (response.statusCode == 200) {
        final statusData = jsonDecode(response.body);
        final newStatus = statusData['status'];
        final newNbDrawings = statusData['nbDrawingsCompleted'] ?? 0;

        setState(() {
          _gameStatus = newStatus;
          _nbDrawingsCompleted = newNbDrawings;
        });

        debugPrint('Status: $newStatus, NbDrawings: $newNbDrawings');

        // Si le status passe à "guessing", naviguer vers la page de jeu mode guessing
        if (newStatus == 'guessing' && !_isNavigating) {
          debugPrint('Status = guessing ! Navigation vers /game mode=guessing');

          setState(() {
            _isNavigating = true;
          });

          _statusTimer?.cancel(); // Annuler le timer avant navigation
          _animationController.stop();

          // Petit délai pour montrer le changement de status
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/game',
              arguments: {
                'gameSessionId': _gameSessionId,
                'mode': 'guessing',
              },
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur vérification status guessing: $e');
    }
  }

  String _getStatusText() {
    switch (_gameStatus) {
      case 'drawing':
        return 'En attente que tous les joueurs terminent leurs dessins...';
      case 'guessing':
        return 'Tous les dessins terminés ! Démarrage de la phase de devinettes...';
      default:
        return 'Préparation en cours...';
    }
  }

  Color _getStatusColor() {
    switch (_gameStatus) {
      case 'drawing':
        return Colors.orange;
      case 'guessing':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (_gameStatus) {
      case 'drawing':
        return Icons.hourglass_empty;
      case 'guessing':
        return Icons.play_arrow;
      default:
        return Icons.sync;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('En attente de la phase de devinettes'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        automaticallyImplyLeading: false, // Empêche le retour
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation de loading
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 3,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(),
                  size: 60,
                  color: _getStatusColor(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Status principal
            Text(
              _getStatusText(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Informations détaillées
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.brush,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Dessins terminés',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Barre de progression (estimation)
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _nbDrawingsCompleted / 12, // 4 joueurs × 3 dessins = 12 max
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Progression globale',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Message d'information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vous avez terminé tous vos dessins !\n'
                      'La phase de devinettes commencera dès que tous les joueurs auront terminé.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_gameStatus == 'guessing') ...[
              const SizedBox(height: 24),

              // Indicateur de démarrage
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Démarrage de la phase de devinettes...',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
