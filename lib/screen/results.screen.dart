import 'dart:convert';
import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final List<Map<String, dynamic>> challenges =
        args?['challenges'] as List<Map<String, dynamic>>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats de la partie'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        automaticallyImplyLeading: false,
      ),
      body: challenges.isEmpty
          ? const Center(child: Text('Aucun résultat disponible'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                return _buildChallengeCard(context, challenges[index], index);
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.home),
            label: const Text('Retour au menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    Map<String, dynamic> challenge,
    int index,
  ) {
    final phrase = _getPhrase(challenge);
    final forbiddenWords = _getForbiddenWords(challenge);
    final imagePath = challenge['image_path'] as String?;
    final prompt = challenge['prompt'] as String?;
    final answers = _getAnswers(challenge);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre du défi
            Text(
              'Défi ${index + 1}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(height: 24),

            // Phrase à deviner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!, width: 2),
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
                    phrase,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Mots interdits
            if (forbiddenWords.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
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
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: forbiddenWords
                          .map(
                            (word) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
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

            const SizedBox(height: 16),

            // Image générée
            if (imagePath != null && imagePath.isNotEmpty) ...[
              const Text(
                'Image générée :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imagePath,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red[400], size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Image non disponible',
                              style: TextStyle(color: Colors.red[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          color: Colors.grey[400], size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune image générée',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Prompt utilisé
            if (prompt != null && prompt.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prompt utilisé :',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[900],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Réponses des joueurs
            const Text(
              'Réponses des joueurs :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            if (answers.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Aucune réponse',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...answers.map((answer) => _buildAnswerItem(answer)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerItem(Map<String, dynamic> answer) {
    final answerText = answer['answer'] as String? ?? '';
    final isResolved = answer['is_resolved'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isResolved ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isResolved ? Colors.green[300]! : Colors.orange[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isResolved ? Icons.check_circle : Icons.cancel,
            color: isResolved ? Colors.green[700] : Colors.orange[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answerText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isResolved ? Colors.green[900] : Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isResolved ? 'Trouvé !' : 'Pas trouvé',
                  style: TextStyle(
                    fontSize: 11,
                    color: isResolved ? Colors.green[600] : Colors.orange[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPhrase(Map<String, dynamic> challenge) {
    final words = [
      challenge['first_word'] ?? '',
      challenge['second_word'] ?? '',
      challenge['third_word'] ?? '',
      challenge['fourth_word'] ?? '',
      challenge['fifth_word'] ?? '',
    ];
    return words.where((w) => w.isNotEmpty).join(' ');
  }

  List<String> _getForbiddenWords(Map<String, dynamic> challenge) {
    final forbiddenWordsJson = challenge['forbidden_words'];

    if (forbiddenWordsJson == null) return [];

    try {
      if (forbiddenWordsJson is List) {
        return forbiddenWordsJson.map((word) => word.toString()).toList();
      } else if (forbiddenWordsJson is String) {
        final List<dynamic> forbiddenList =
            (forbiddenWordsJson as String).isEmpty
                ? []
                : [forbiddenWordsJson];
        return forbiddenList.map((word) => word.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Erreur parsing forbidden words: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _getAnswers(Map<String, dynamic> challenge) {
    // Try 'proposals' first (API field), then 'answers' (local field)
    final answersData = challenge['proposals'] ?? challenge['answers'];

    if (answersData == null) return [];

    try {
      // If it's a JSON string, parse it first
      if (answersData is String) {
        if (answersData.isEmpty) return [];
        final parsed = jsonDecode(answersData);
        if (parsed is List) {
          return parsed.map((a) => a as Map<String, dynamic>).toList();
        }
      }
      // If it's already a list, use it directly
      else if (answersData is List) {
        return answersData.map((a) => a as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Erreur parsing answers: $e');
      return [];
    }
  }
}
