import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/global_data.dart' as global;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _gameSessionId;
  String _gameMode = 'drawing'; // 'drawing' ou 'guessing'
  List<Map<String, dynamic>> _challenges = [];
  int _currentChallengeIndex = 0;
  bool _isLoading = true;
  bool _isSendingPrompt = false;
  bool _hasImageGenerated = false;
  bool _hasAnswered = false;
  String? _currentImageUrl;

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _gameSessionId = args['gameSessionId'];
        // Déterminer le mode : 'drawing' (défaut) ou 'guessing'
        _gameMode = args['mode'] ?? 'drawing';
        _loadMyChallenges();
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadMyChallenges() async {
    if (_gameSessionId == null) return;

    try {
      print('=== CHARGEMENT DES CHALLENGES (${_gameMode.toUpperCase()}) ===');

      // Endpoint différent selon le mode
      final endpoint = _gameMode == 'guessing'
          ? 'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/myChallengesToGuess'
          : 'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/myChallenges';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer ${global.token}'},
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final challengesData = jsonDecode(response.body) as List;

        setState(() {
          _challenges =
              challengesData
                  .map((challenge) => challenge as Map<String, dynamic>)
                  .toList();
          _isLoading = false;
          _currentChallengeIndex = 0;
        });

        print('Challenges chargés: ${_challenges.length}');

        // Vérifier si le challenge actuel a déjà une image
        _checkCurrentChallengeImage();
      } else {
        print('Erreur 400 détails: ${response.body}');
        print('Headers: ${response.headers}');
        print('Request URL: ${response.request?.url}');
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur chargement challenges: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Impossible de charger les défis: $e');
    }
  }

  void _checkCurrentChallengeImage() {
    if (_challenges.isNotEmpty && _currentChallengeIndex < _challenges.length) {
      final currentChallenge = _challenges[_currentChallengeIndex];
      final imagePath = currentChallenge['image_path'];

      setState(() {
        _hasImageGenerated =
            imagePath != null && imagePath.toString().isNotEmpty;
        _currentImageUrl = _hasImageGenerated ? imagePath : null;

        // En mode guessing, vérifier si le challenge a déjà été répondu
        if (_gameMode == 'guessing') {
          final answers = currentChallenge['answers'];
          _hasAnswered = answers != null &&
              (answers is List && answers.isNotEmpty ||
                  answers is Map && answers.isNotEmpty);
        }
      });
    }
  }

  String _getCurrentPhrase() {
    if (_challenges.isEmpty || _currentChallengeIndex >= _challenges.length) {
      return '';
    }

    final challenge = _challenges[_currentChallengeIndex];
    return '${challenge['first_word']} ${challenge['second_word']} ${challenge['third_word']} ${challenge['fourth_word']} ${challenge['fifth_word']}';
  }

  List<String> _getCurrentForbiddenWords() {
    if (_challenges.isEmpty || _currentChallengeIndex >= _challenges.length) {
      return [];
    }

    final challenge = _challenges[_currentChallengeIndex];
    final forbiddenWordsJson = challenge['forbidden_words'];

    if (forbiddenWordsJson == null) return [];

    try {
      // Parse le JSON string vers une liste
      final List<dynamic> forbiddenList = jsonDecode(forbiddenWordsJson);
      return forbiddenList.map((word) => word.toString()).toList();
    } catch (e) {
      print('Erreur parsing forbidden words: $e');
      return [];
    }
  }

  Future<void> _sendPrompt() async {
    if (_gameSessionId == null ||
        _challenges.isEmpty ||
        _currentChallengeIndex >= _challenges.length ||
        _promptController.text.trim().isEmpty ||
        _isSendingPrompt ||
        _hasImageGenerated) {
      return;
    }

    final challengeId = _challenges[_currentChallengeIndex]['id'];
    final prompt = _promptController.text.trim();

    setState(() {
      _isSendingPrompt = true;
    });

    try {
      print('=== ENVOI DU PROMPT ===');
      print('Challenge ID: $challengeId');
      print('Prompt: $prompt');

      final response = await http.post(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/challenges/$challengeId/draw',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${global.token}',
        },
        body: jsonEncode({'prompt': prompt}),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // L'API peut retourner directement l'URL de l'image ou juste un succès
        String? imageUrl;
        if (responseData is Map && responseData.containsKey('image_path')) {
          imageUrl = responseData['image_path'];
        } else if (responseData is Map &&
            responseData.containsKey('image_url')) {
          imageUrl = responseData['image_url'];
        }

        setState(() {
          _hasImageGenerated = true;
          _currentImageUrl = imageUrl;
          _isSendingPrompt = false;
        });

        // Mise à jour du challenge dans la liste locale
        _challenges[_currentChallengeIndex]['image_path'] = imageUrl;
        _challenges[_currentChallengeIndex]['prompt'] = prompt;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image générée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur envoi prompt: $e');
      setState(() {
        _isSendingPrompt = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitAnswer({required bool isResolved}) async {
    if (_gameSessionId == null ||
        _challenges.isEmpty ||
        _currentChallengeIndex >= _challenges.length ||
        _isSendingPrompt) {
      return;
    }

    final challengeId = _challenges[_currentChallengeIndex]['id'];
    final answer = _answerController.text.trim();

    setState(() {
      _isSendingPrompt = true;
    });

    try {
      print('=== ENVOI DE LA RÉPONSE ===');
      print('Challenge ID: $challengeId');
      print('Answer: $answer');
      print('Is resolved: $isResolved');

      final response = await http.post(
        Uri.parse(
          'https://pictioniary.wevox.cloud/api/game_sessions/$_gameSessionId/challenges/$challengeId/answer',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${global.token}',
        },
        body: jsonEncode({
          'answer': answer,
          'is_resolved': isResolved,
        }),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _hasAnswered = true;
          _isSendingPrompt = false;
        });

        // Mise à jour du challenge dans la liste locale
        if (_challenges[_currentChallengeIndex]['answers'] == null) {
          _challenges[_currentChallengeIndex]['answers'] = [];
        }
        (_challenges[_currentChallengeIndex]['answers'] as List).add({
          'answer': answer,
          'is_resolved': isResolved,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isResolved ? 'Bravo ! Réponse correcte !' : 'Réponse enregistrée',
            ),
            backgroundColor: isResolved ? Colors.green : Colors.orange,
          ),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur envoi réponse: $e');
      setState(() {
        _isSendingPrompt = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _nextChallenge() {
    if (_currentChallengeIndex < _challenges.length - 1) {
      setState(() {
        _currentChallengeIndex++;
        _promptController.clear();
        _answerController.clear();
        _hasAnswered = false;
      });
      _checkCurrentChallengeImage();
    } else {
      // Tous les challenges terminés - naviguer vers l'écran d'attente
      Navigator.pushReplacementNamed(
        context,
        '/waiting-results',
        arguments: {'gameSessionId': _gameSessionId},
      );
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
    final title = _gameMode == 'guessing'
        ? 'À deviner ${_currentChallengeIndex + 1}/${_challenges.length}'
        : 'Défi ${_currentChallengeIndex + 1}/${_challenges.length}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        automaticallyImplyLeading: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _challenges.isEmpty
              ? const Center(child: Text('Aucun défi trouvé'))
              : _buildGameContent(),
    );
  }

  Widget _buildGameContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En mode DRAWING : afficher phrase + mots interdits
          if (_gameMode == 'drawing') ...[
            // Phrase à deviner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Phrase à faire deviner :',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCurrentPhrase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mots interdits
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mots interdits :',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getCurrentForbiddenWords()
                        .map(
                          (word) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Text(
                              word,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // En mode GUESSING : afficher un message d'instruction
          if (_gameMode == 'guessing') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.purple[700],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Devinez la phrase à 5 mots !',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Regardez l\'image et essayez de deviner',
                    style: TextStyle(
                      color: Colors.purple[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Zone d'image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _buildImageArea(),
            ),
          ),

          const SizedBox(height: 16),

          // Zone de prompt (mode drawing)
          if (_gameMode == 'drawing' && !_hasImageGenerated)
            _buildPromptArea(),

          // Zone de réponse (mode guessing)
          if (_gameMode == 'guessing' && !_hasAnswered) _buildAnswerArea(),

          // Bouton suivant
          if ((_gameMode == 'drawing' && _hasImageGenerated) ||
              (_gameMode == 'guessing' && _hasAnswered))
            _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    if (_hasImageGenerated && _currentImageUrl != null) {
      // Afficher l'image générée
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _currentImageUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur de chargement de l\'image',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Placeholder en attente d'image
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'L\'image apparaîtra ici',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Écrivez un prompt pour générer l\'image',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPromptArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créez votre prompt pour l\'IA :',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Décrivez l\'image que vous voulez générer pour faire deviner la phrase.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  hintText: 'Ex: Une poule colorée sur un mur de briques...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit),
                  suffixIcon:
                      _promptController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _promptController.clear();
                              setState(() {});
                            },
                          )
                          : null,
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),

            ElevatedButton.icon(
              onPressed:
                  _promptController.text.trim().isNotEmpty && !_isSendingPrompt
                      ? _sendPrompt
                      : null,
              icon:
                  _isSendingPrompt
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send),
              label: Text(_isSendingPrompt ? 'Génération...' : 'Générer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre réponse :',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Écrivez la phrase à 5 mots que vous pensez être la bonne réponse.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _answerController,
          decoration: InputDecoration(
            hintText: 'Ex: une poule sur un mur',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lightbulb),
            suffixIcon: _answerController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _answerController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {});
          },
        ),

        const SizedBox(height: 12),

        // Boutons de soumission
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _answerController.text.trim().isNotEmpty &&
                        !_isSendingPrompt
                    ? () => _submitAnswer(isResolved: false)
                    : null,
                icon: _isSendingPrompt
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close),
                label: Text(
                    _isSendingPrompt ? 'Envoi...' : 'Pas trouvé (passer)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _answerController.text.trim().isNotEmpty &&
                        !_isSendingPrompt
                    ? () => _submitAnswer(isResolved: true)
                    : null,
                icon: _isSendingPrompt
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSendingPrompt ? 'Envoi...' : 'Trouvé !'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final isLastChallenge = _currentChallengeIndex >= _challenges.length - 1;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _nextChallenge,
        icon: Icon(isLastChallenge ? Icons.check : Icons.arrow_forward),
        label: Text(
          isLastChallenge
              ? 'Terminer'
              : 'Défi suivant (${_currentChallengeIndex + 2}/${_challenges.length})',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isLastChallenge ? Colors.green : Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
