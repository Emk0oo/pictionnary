import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../data/global_data.dart' as global;

class JoinWaitingRoomScreen extends StatefulWidget {
  const JoinWaitingRoomScreen({super.key});

  @override
  State<JoinWaitingRoomScreen> createState() => _JoinWaitingRoomScreenState();
}

class _JoinWaitingRoomScreenState extends State<JoinWaitingRoomScreen> {
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _gameSessionId;
  String? _playerTeam;
  Map<String, dynamic>? _gameSession;
  Map<int, String> _playerNames = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _gameSessionId = args['gameSessionId'];
        _playerTeam = args['team'];
        _loadGameSession();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Charger les informations de la session
  Future<void> _loadGameSession() async {
    if (_gameSessionId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _gameSession = responseData;
          _isLoading = false;
        });
        await _loadPlayerNames();

        // Démarrer le rafraîchissement automatique
        _startRefreshing();
      } else {
        throw Exception('Session introuvable');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Impossible de charger la partie: $e');
    }
  }

  // Démarrer le rafraîchissement automatique
  void _startRefreshing() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshGameSession();
    });
  }

  // Rafraîchir la session
  Future<void> _refreshGameSession() async {
    if (_gameSessionId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _gameSession = responseData;
        });
        await _loadPlayerNames();

        // Vérifier si la partie a commencé
        if (_gameSession!['status'] == 'in_progress' ||
            _gameSession!['status'] == 'started') {
          Navigator.pushReplacementNamed(
            context,
            '/game',
            arguments: {'gameSessionId': _gameSessionId},
          );
        }
      }
    } catch (e) {
      print('Erreur refresh: $e');
    }
  }

  // Quitter la session
  Future<void> _leaveSession() async {
    if (_gameSessionId == null) return;

    try {
      await http.get(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/leave',
        ),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );
    } catch (e) {
      print('Erreur leave: $e');
    }
    Navigator.pop(context);
  }

  // Charger les noms des joueurs
  Future<void> _loadPlayerNames() async {
    final allPlayerIds = _getAllPlayers();

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
          }
        } catch (e) {
          print('Erreur chargement joueur $playerId: $e');
        }
      }
    }
  }

  // Récupérer tous les joueurs
  List<int> _getAllPlayers() {
    if (_gameSession == null) return [];

    List<int> allPlayers = [];

    if (_gameSession!['red_player_1'] != null) {
      allPlayers.add(_gameSession!['red_player_1']);
    }
    if (_gameSession!['red_player_2'] != null) {
      allPlayers.add(_gameSession!['red_player_2']);
    }
    if (_gameSession!['blue_player_1'] != null) {
      allPlayers.add(_gameSession!['blue_player_1']);
    }
    if (_gameSession!['blue_player_2'] != null) {
      allPlayers.add(_gameSession!['blue_player_2']);
    }

    return allPlayers;
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
                Navigator.of(context).pop();
              },
              child: const Text('Retour'),
            ),
          ],
        );
      },
    );
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
          title: Text('Partie ${_gameSessionId ?? "..."}'),
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: _leaveSession,
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildPlayerInfo(),
          const SizedBox(height: 16),
          _buildGameInfo(),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTeamDisplay('Équipe Rouge', Colors.red, 'red'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTeamDisplay('Équipe Bleue', Colors.blue, 'blue'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildWaitingMessage(),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _playerTeam == 'red' ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _playerTeam == 'red' ? Colors.red[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            color: _playerTeam == 'red' ? Colors.red[600] : Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Vous êtes dans l\'équipe ${_playerTeam == 'red' ? 'rouge' : 'bleue'}',
            style: TextStyle(
              color: _playerTeam == 'red' ? Colors.red[700] : Colors.blue[700],
              fontWeight: FontWeight.w500,
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '${allPlayers.length}/4 joueurs connectés',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDisplay(String teamName, Color teamColor, String team) {
    List<int> teamPlayers = [];

    if (team == 'red' && _gameSession != null) {
      if (_gameSession!['red_player_1'] != null) {
        teamPlayers.add(_gameSession!['red_player_1']);
      }
      if (_gameSession!['red_player_2'] != null) {
        teamPlayers.add(_gameSession!['red_player_2']);
      }
    } else if (team == 'blue' && _gameSession != null) {
      if (_gameSession!['blue_player_1'] != null) {
        teamPlayers.add(_gameSession!['blue_player_1']);
      }
      if (_gameSession!['blue_player_2'] != null) {
        teamPlayers.add(_gameSession!['blue_player_2']);
      }
    }

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

  Widget _buildWaitingMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange[600]),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'En attente que le créateur de la partie lance le jeu...',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
