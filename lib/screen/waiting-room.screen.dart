import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/global_data.dart' as global;

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isCreatingSession = false;
  String? _gameSessionId;
  Map<String, dynamic>? _gameSession;
  Map<int, String> _playerNames = {}; // Cache des noms de joueurs
  bool _canStartGame = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createAndJoinGameSession();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Créer une nouvelle session de jeu puis la rejoindre
  Future<void> _createAndJoinGameSession() async {
    setState(() {
      _isCreatingSession = true;
      _errorMessage = null;
    });

    try {
      print('=== DÉBUT CRÉATION SESSION ===');
      print('Token: ${global.token}');

      // 1. Créer la session
      final createResponse = await http.post(
        Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${global.token}',
        },
      );

      print('Status création: ${createResponse.statusCode}');
      print('Réponse création: ${createResponse.body}');

      if (createResponse.statusCode == 200 ||
          createResponse.statusCode == 201) {
        final createData = jsonDecode(createResponse.body);
        final sessionId = createData['id'].toString();

        print('Session créée avec ID: $sessionId');

        // 2. Rejoindre la session qu'on vient de créer avec la couleur rouge (créateur = rouge)
        print('=== DÉBUT JOIN SESSION ===');
        final joinResponse = await http.post(
          Uri.parse(
            'https://pictioniary.wevox.cloud/api/game_sessions/$sessionId/join',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${global.token}',
          },
          body: jsonEncode({'color': 'red'}),
        );

        print('Status join: ${joinResponse.statusCode}');
        print('Réponse join: ${joinResponse.body}');

        if (joinResponse.statusCode == 200 || joinResponse.statusCode == 201) {
          setState(() {
            _gameSessionId = sessionId;
            _isCreatingSession = false;
            _isLoading = false;
          });

          print('Session rejointe avec succès');

          // 3. Rafraîchir immédiatement pour récupérer l'état
          await _refreshGameSession();

          // 4. Démarrer le rafraîchissement automatique
          _startRefreshing();
        } else {
          throw Exception(
            'Erreur JOIN ${joinResponse.statusCode}: ${joinResponse.body}',
          );
        }
      } else {
        throw Exception(
          'Erreur CRÉATION ${createResponse.statusCode}: ${createResponse.body}',
        );
      }
    } catch (e) {
      print('ERREUR GLOBALE: $e');
      setState(() {
        _isCreatingSession = false;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Démarrer le rafraîchissement automatique
  void _startRefreshing() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshGameSession();
    });
  }

  // Récupérer les informations de la session
  Future<void> _refreshGameSession() async {
    if (_gameSessionId == null) return;

    try {
      print('=== REFRESH SESSION $_gameSessionId ===');
      final response = await http.get(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      print('Status refresh: ${response.statusCode}');
      print('Réponse refresh: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _gameSession = responseData;
          _checkCanStartGame();
        });
        await _loadPlayerNames();
      } else {
        print('Erreur refresh: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erreur lors du rafraîchissement: $e');
    }
  }

  // Récupérer tous les joueurs des deux équipes
  List<int> _getAllPlayers() {
    if (_gameSession == null) return [];

    List<int> allPlayers = [];

    // Ajouter les joueurs individuels de l'équipe rouge
    if (_gameSession!['red_player_1'] != null) {
      allPlayers.add(_gameSession!['red_player_1']);
    }
    if (_gameSession!['red_player_2'] != null) {
      allPlayers.add(_gameSession!['red_player_2']);
    }

    // Ajouter les joueurs individuels de l'équipe bleue
    if (_gameSession!['blue_player_1'] != null) {
      allPlayers.add(_gameSession!['blue_player_1']);
    }
    if (_gameSession!['blue_player_2'] != null) {
      allPlayers.add(_gameSession!['blue_player_2']);
    }

    return allPlayers;
  }

  // Récupérer les joueurs de l'équipe rouge
  List<int> _getRedTeamPlayers() {
    if (_gameSession == null) return [];

    List<int> redPlayers = [];

    if (_gameSession!['red_player_1'] != null) {
      redPlayers.add(_gameSession!['red_player_1']);
    }
    if (_gameSession!['red_player_2'] != null) {
      redPlayers.add(_gameSession!['red_player_2']);
    }

    return redPlayers;
  }

  // Récupérer les joueurs de l'équipe bleue
  List<int> _getBlueTeamPlayers() {
    if (_gameSession == null) return [];

    List<int> bluePlayers = [];

    if (_gameSession!['blue_player_1'] != null) {
      bluePlayers.add(_gameSession!['blue_player_1']);
    }
    if (_gameSession!['blue_player_2'] != null) {
      bluePlayers.add(_gameSession!['blue_player_2']);
    }

    return bluePlayers;
  }

  // Vérifier si on peut démarrer le jeu (au moins 2 joueurs)
  void _checkCanStartGame() {
    final allPlayers = _getAllPlayers();
    _canStartGame = allPlayers.length >= 2;
    print('Joueurs total: ${allPlayers.length}, Peut démarrer: $_canStartGame');
  }

  // Charger les noms des joueurs
  Future<void> _loadPlayerNames() async {
    final allPlayerIds = _getAllPlayers();
    print('IDs joueurs à charger: $allPlayerIds');

    for (int playerId in allPlayerIds) {
      if (!_playerNames.containsKey(playerId)) {
        try {
          final response = await http.get(
            Uri.parse('https://pictioniary.wevox.cloud/api/players/$playerId'),
            headers: {'Authorization': 'Bearer ${global.token}'},
          );

          if (response.statusCode == 200) {
            final playerData = jsonDecode(response.body);
            setState(() {
              _playerNames[playerId] = playerData['name'];
            });
            print('Nom joueur chargé: ${playerId} -> ${playerData['name']}');
          }
        } catch (e) {
          print('Erreur lors du chargement du joueur $playerId: $e');
        }
      }
    }
  }

  // Quitter la session
  Future<void> _leaveSession() async {
    if (_gameSessionId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/leave',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erreur lors de la sortie de session: $e');
      Navigator.pop(context);
    }
  }

  // Démarrer la partie
  Future<void> _startGame() async {
    if (_gameSessionId == null || !_canStartGame) return;

    try {
      final response = await http.post(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/start',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(
          context,
          '/game',
          arguments: {'gameSessionId': _gameSessionId},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du démarrage de la partie'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveSession();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Salon ${_gameSessionId ?? "..."}'),
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: _leaveSession,
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body:
            _isLoading || _isCreatingSession
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Création et connexion à la partie...'),
                    ],
                  ),
                )
                : _errorMessage != null
                ? _buildErrorContent()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erreur lors de la création de la partie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _createAndJoinGameSession();
              },
              child: const Text('Réessayer'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildQRCodeSection(),
          const SizedBox(height: 24),
          _buildGameInfo(),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTeamSection('Équipe Rouge', Colors.red, 'red'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTeamSection('Équipe Bleue', Colors.blue, 'blue'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Partager cette partie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_gameSessionId != null)
            QrImageView(
              data: _gameSessionId!,
              version: QrVersions.auto,
              size: 120.0,
            ),
          const SizedBox(height: 8),
          Text(
            'Code: ${_gameSessionId ?? "..."}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    final allPlayers = _getAllPlayers();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '${allPlayers.length}/4 joueurs connectés',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(String teamName, Color teamColor, String team) {
    final List<int> teamPlayers =
        team == 'red' ? _getRedTeamPlayers() : _getBlueTeamPlayers();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: teamColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: teamColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: teamColor,
                  ),
                ),
              ),
              Text(
                '${teamPlayers.length}/2',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: teamColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < 2; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          i < teamPlayers.length
                              ? teamColor.withOpacity(0.1)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            i < teamPlayers.length
                                ? teamColor
                                : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          i < teamPlayers.length
                              ? Icons.person
                              : Icons.person_outline,
                          color:
                              i < teamPlayers.length
                                  ? teamColor
                                  : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            i < teamPlayers.length
                                ? _playerNames[teamPlayers[i]] ??
                                    'Chargement...'
                                : 'En attente...',
                            style: TextStyle(
                              color:
                                  i < teamPlayers.length
                                      ? teamColor
                                      : Colors.grey[600],
                              fontWeight:
                                  i < teamPlayers.length
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _canStartGame ? _startGame : null,
        icon: const Icon(Icons.play_arrow),
        label: Text(
          _canStartGame
              ? 'Démarrer la partie'
              : 'En attente de joueurs (minimum 2)...',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: _canStartGame ? Colors.green : null,
        ),
      ),
    );
  }
}
