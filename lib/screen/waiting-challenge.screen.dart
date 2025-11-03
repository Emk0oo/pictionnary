import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../data/global_data.dart' as global;

class WaitingChallengesScreen extends StatefulWidget {
  const WaitingChallengesScreen({super.key});

  @override
  State<WaitingChallengesScreen> createState() => _WaitingChallengesScreenState();
}

class _WaitingChallengesScreenState extends State<WaitingChallengesScreen>
    with TickerProviderStateMixin {
  String? _gameSessionId;
  Timer? _statusTimer;
  String _gameStatus = 'challenge';
  int _nbChallenges = 0;
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
      print('=== VÉRIFICATION STATUS CHALLENGES ===');
      
      final response = await http.get(
        Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/status'),
        headers: {
          'Authorization': 'Bearer ${global.token}',
        },
      );

      print('Status response: ${response.statusCode}');
      print('Status body: ${response.body}');

      if (response.statusCode == 200) {
        final statusData = jsonDecode(response.body);
        final newStatus = statusData['status'];
        final newNbChallenges = statusData['nbChallenges'] ?? 0;
        
        setState(() {
          _gameStatus = newStatus;
          _nbChallenges = newNbChallenges;
        });

        print('Status: $newStatus, NbChallenges: $newNbChallenges');

        // Si le status passe à "drawing", naviguer vers la page de jeu
        if (newStatus == 'drawing' && !_isNavigating) {
          print('Status = drawing ! Navigation vers /game');
          
          setState(() {
            _isNavigating = true;
          });
          
          _animationController.stop();
          
          // Petit délai pour montrer le changement de status
          await Future.delayed(const Duration(milliseconds: 500));
          
          Navigator.pushReplacementNamed(
            context,
            '/game',
            arguments: {
              'gameSessionId': _gameSessionId,
              'mode': 'drawing',
            },
          );
        }
      }
    } catch (e) {
      print('Erreur vérification status challenges: $e');
    }
  }

  String _getStatusText() {
    switch (_gameStatus) {
      case 'challenge':
        return 'En attente des défis des autres joueurs...';
      case 'drawing':
        return 'Tous les défis reçus ! Démarrage du jeu...';
      default:
        return 'Préparation en cours...';
    }
  }

  Color _getStatusColor() {
    switch (_gameStatus) {
      case 'challenge':
        return Colors.orange;
      case 'drawing':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (_gameStatus) {
      case 'challenge':
        return Icons.hourglass_empty;
      case 'drawing':
        return Icons.play_arrow;
      default:
        return Icons.sync;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préparation de la partie'),
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
                        Icons.assignment,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Défis collectés',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Barre de progression
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _nbChallenges / 12, // 4 joueurs × 3 défis = 12 défis max
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
                    '$_nbChallenges / 12 défis reçus',
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
                      'Vos défis ont été envoyés avec succès !\n'
                      'La partie commencera dès que tous les joueurs auront terminé.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_gameStatus == 'drawing') ...[
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
                      'Démarrage de la partie...',
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