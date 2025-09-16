import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/global_data.dart' as global;

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  String? _gameSessionId;
  List<Map<String, dynamic>> _challenges = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _gameSessionId = args['gameSessionId'];
        print('Game Session ID reçu: $_gameSessionId');
      }
    });
  }

  void _showCreateChallengeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CreateChallengeModal(
            onChallengeCreated: (challenge) {
              setState(() {
                _challenges.add(challenge);
              });
            },
          ),
    );
  }

  void _removeChallenge(int index) {
    setState(() {
      _challenges.removeAt(index);
    });
  }

  Future<void> _testSingleChallenge() async {
    if (_gameSessionId == null) return;

    print('=== TEST D\'UN SEUL CHALLENGE ===');

    final testPayload = {
      'first_word': 'une',
      'second_word': 'poule',
      'third_word': 'sur',
      'fourth_word': 'un',
      'fifth_word': 'mur',
      'forbidden_words': ['volaille', 'brique', 'poulet'],
    };

    print('Test payload: ${jsonEncode(testPayload)}');
    print(
      'URL: https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/challenges',
    );
    print('Token: ${global.token}');

    try {
      final response = await http.post(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/challenges',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${global.token}',
        },
        body: jsonEncode(testPayload),
      );

      print('Test Status: ${response.statusCode}');
      print('Test Headers: ${response.headers}');
      print('Test Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test réussi !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test échoué: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erreur test: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur test: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendChallenges() async {
    if (_challenges.length != 3 || _gameSessionId == null || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      print('=== ENVOI DES 3 CHALLENGES ===');
      print('Game Session ID: $_gameSessionId');
      print('Nombre de challenges: ${_challenges.length}');
      print('Token: ${global.token}');

      for (int i = 0; i < _challenges.length; i++) {
        final challenge = _challenges[i];

        print('\n--- Challenge ${i + 1}/3 ---');
        print('Challenge data: $challenge');

        // Préparation du payload
        final payload = {
          'first_word': challenge['first_word'],
          'second_word': challenge['second_word'],
          'third_word': challenge['third_word'],
          'fourth_word': challenge['fourth_word'],
          'fifth_word': challenge['fifth_word'],
          'forbidden_words': challenge['forbidden_words'],
        };

        print('Payload à envoyer: ${jsonEncode(payload)}');
        print(
          'URL complète: https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/challenges',
        );

        final response = await http.post(
          Uri.parse(
            'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/challenges',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${global.token}',
          },
          body: jsonEncode(payload),
        );

        print('Challenge ${i + 1} - Status: ${response.statusCode}');
        print('Challenge ${i + 1} - Headers: ${response.headers}');
        print('Challenge ${i + 1} - Réponse complète: ${response.body}');

        if (response.statusCode != 200 && response.statusCode != 201) {
          // Plus de détails sur l'erreur
          print('ERREUR DÉTAILLÉE:');
          print(
            'URL: https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/challenges',
          );
          print(
            'Headers envoyés: Content-Type: application/json, Authorization: Bearer ${global.token}',
          );
          print('Body envoyé: ${jsonEncode(payload)}');

          String errorMessage = 'Erreur ${response.statusCode}';

          // Essayer de parser la réponse d'erreur
          try {
            final errorData = jsonDecode(response.body);
            if (errorData is Map && errorData.containsKey('message')) {
              errorMessage = errorData['message'];
            } else if (errorData is Map && errorData.containsKey('error')) {
              errorMessage = errorData['error'];
            }
          } catch (e) {
            print('Impossible de parser l\'erreur JSON: $e');
          }

          throw Exception(
            'Challenge ${i + 1}: $errorMessage (${response.statusCode})',
          );
        }

        print('✅ Challenge ${i + 1} envoyé avec succès');
      }

      print('\n🎉 Tous les challenges envoyés avec succès !');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vos défis ont été envoyés !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigation vers l'écran d'attente des challenges
      Navigator.pushReplacementNamed(
        context,
        '/waiting-challenges',
        arguments: {'gameSessionId': _gameSessionId},
      );
    } catch (e) {
      print('❌ ERREUR GLOBALE: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer les défis'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créez 3 défis pour la partie',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Chaque défi doit comporter une phrase à faire deviner et 3 mots interdits.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),

            // Debug info
            if (_gameSessionId != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text('Session ID: $_gameSessionId'),
                    Text('Token: ${global.token?.substring(0, 20)}...'),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Compteur de défis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _challenges.length == 3
                        ? Colors.green[50]
                        : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _challenges.length == 3
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _challenges.length == 3 ? Icons.check_circle : Icons.info,
                    color:
                        _challenges.length == 3
                            ? Colors.green[600]
                            : Colors.orange[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_challenges.length}/3 défis créés',
                    style: TextStyle(
                      color:
                          _challenges.length == 3
                              ? Colors.green[700]
                              : Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Liste des défis
            Expanded(
              child:
                  _challenges.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        itemCount: _challenges.length,
                        itemBuilder: (context, index) {
                          return _buildChallengeCard(index);
                        },
                      ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _challenges.length < 3 && !_isSending
                                ? _showCreateChallengeModal
                                : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un défi'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _challenges.length == 3 && !_isSending
                                ? _sendChallenges
                                : null,
                        icon:
                            _isSending
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(Icons.send),
                        label: Text(
                          _isSending ? 'Envoi...' : 'Envoyer les défis',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _challenges.length == 3 ? Colors.green : null,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bouton de test
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _gameSessionId != null && !_isSending
                            ? _testSingleChallenge
                            : null,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Test 1 défi (Debug)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun défi créé',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur "Ajouter un défi" pour commencer',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(int index) {
    final challenge = _challenges[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Défi ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (!_isSending)
                  IconButton(
                    onPressed: () => _removeChallenge(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Phrase à deviner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phrase à deviner :',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${challenge['first_word']} ${challenge['second_word']} ${challenge['third_word']} ${challenge['fourth_word']} ${challenge['fifth_word']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Mots interdits
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mots interdits :',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        (challenge['forbidden_words'] as List<String>)
                            .map(
                              (word) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[300]!),
                                ),
                                child: Text(
                                  word,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateChallengeModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onChallengeCreated;

  const CreateChallengeModal({super.key, required this.onChallengeCreated});

  @override
  State<CreateChallengeModal> createState() => _CreateChallengeModalState();
}

class _CreateChallengeModalState extends State<CreateChallengeModal> {
  final _formKey = GlobalKey<FormState>();

  String _firstWord = 'un';
  final TextEditingController _secondWordController = TextEditingController();
  String _thirdWord = 'sur';
  String _fourthWord = 'un';
  final TextEditingController _fifthWordController = TextEditingController();

  final TextEditingController _forbidden1Controller = TextEditingController();
  final TextEditingController _forbidden2Controller = TextEditingController();
  final TextEditingController _forbidden3Controller = TextEditingController();

  @override
  void dispose() {
    _secondWordController.dispose();
    _fifthWordController.dispose();
    _forbidden1Controller.dispose();
    _forbidden2Controller.dispose();
    _forbidden3Controller.dispose();
    super.dispose();
  }

  void _createChallenge() {
    if (_formKey.currentState!.validate()) {
      final challenge = {
        'first_word': _firstWord,
        'second_word': _secondWordController.text.trim(),
        'third_word': _thirdWord,
        'fourth_word': _fourthWord,
        'fifth_word': _fifthWordController.text.trim(),
        'forbidden_words': [
          _forbidden1Controller.text.trim(),
          _forbidden2Controller.text.trim(),
          _forbidden3Controller.text.trim(),
        ],
      };

      // Debug du challenge créé
      print('=== CHALLENGE CRÉÉ ===');
      print('Challenge data: $challenge');
      print('Types: ');
      print(
        '  first_word: ${challenge['first_word'].runtimeType} = "${challenge['first_word']}"',
      );
      print(
        '  second_word: ${challenge['second_word'].runtimeType} = "${challenge['second_word']}"',
      );
      print(
        '  third_word: ${challenge['third_word'].runtimeType} = "${challenge['third_word']}"',
      );
      print(
        '  fourth_word: ${challenge['fourth_word'].runtimeType} = "${challenge['fourth_word']}"',
      );
      print(
        '  fifth_word: ${challenge['fifth_word'].runtimeType} = "${challenge['fifth_word']}"',
      );
      print(
        '  forbidden_words: ${challenge['forbidden_words'].runtimeType} = ${challenge['forbidden_words']}',
      );
      print('JSON: ${jsonEncode(challenge)}');

      widget.onChallengeCreated(challenge);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Créer un défi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Construction de la phrase
                      const Text(
                        'Construisez votre phrase :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Première ligne : [un/une] + [mot]
                      Row(
                        children: [
                          // Premier dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _firstWord,
                                onChanged: (value) {
                                  setState(() {
                                    _firstWord = value!;
                                  });
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: 'un',
                                    child: Text('un'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'une',
                                    child: Text('une'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Premier champ texte
                          Expanded(
                            child: TextFormField(
                              controller: _secondWordController,
                              decoration: const InputDecoration(
                                hintText: 'premier mot',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requis';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {}); // Pour mettre à jour l'aperçu
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Deuxième ligne : [sur/dans] + [un/une] + [mot]
                      Row(
                        children: [
                          // Deuxième dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _thirdWord,
                                onChanged: (value) {
                                  setState(() {
                                    _thirdWord = value!;
                                  });
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: 'sur',
                                    child: Text('sur'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'dans',
                                    child: Text('dans'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Troisième dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _fourthWord,
                                onChanged: (value) {
                                  setState(() {
                                    _fourthWord = value!;
                                  });
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: 'un',
                                    child: Text('un'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'une',
                                    child: Text('une'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Deuxième champ texte
                          Expanded(
                            child: TextFormField(
                              controller: _fifthWordController,
                              decoration: const InputDecoration(
                                hintText: 'deuxième mot',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requis';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {}); // Pour mettre à jour l'aperçu
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Aperçu de la phrase
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aperçu :',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_firstWord ${_secondWordController.text.isNotEmpty ? _secondWordController.text : '[premier mot]'} $_thirdWord $_fourthWord ${_fifthWordController.text.isNotEmpty ? _fifthWordController.text : '[deuxième mot]'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Mots interdits
                      const Text(
                        'Mots interdits :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _forbidden1Controller,
                        decoration: const InputDecoration(
                          labelText: 'Mot interdit 1',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _forbidden2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Mot interdit 2',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _forbidden3Controller,
                        decoration: const InputDecoration(
                          labelText: 'Mot interdit 3',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requis';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createChallenge,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer le défi'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
