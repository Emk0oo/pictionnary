import 'package:flutter/material.dart';
import '../data/global_data.dart' as global;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isLoggedIn = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulation d'une connexion
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _isLoggedIn = true;
      });
    }
  }

  void _handleNewGame() {
    // Navigation vers création de nouvelle partie
    Navigator.pushNamed(context, '/new-game');
  }

  void _handleJoinGame() {
    // Navigation vers rejoindre une partie
    Navigator.pushNamed(context, '/join-game');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icône de l'app
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.brush,
                      size: 60,
                      color: Color(0xFF6C63FF),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Titre de l'application
                  Text(
                    'Pictionary',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 36,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Carte principale
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child:
                          _isLoggedIn
                              ? _buildWelcomeContent()
                              : _buildLoginContent(),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Champ nom d'utilisateur
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Nom d\'utilisateur',
              prefixIcon: Icon(Icons.person),
              hintText: 'Entre ton pseudo',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer un nom d\'utilisateur';
              }
              if (value.trim().length < 2) {
                return 'Le nom doit contenir au moins 2 caractères';
              }
              if (value.trim().length > 15) {
                return 'Le nom ne peut pas dépasser 15 caractères';
              }
              return null;
            },
            onChanged: (value) => global.username = value.trim(),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
          ),

          const SizedBox(height: 24),

          // Bouton de connexion
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text('Commencer à jouer'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),

        // Message de bienvenue
        Text(
          'Bienvenue ${global.username} !',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Prêt à jouer au Pictionary ?',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Bouton Nouvelle partie
        ElevatedButton.icon(
          onPressed: _handleNewGame,
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle partie'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 16),

        // Bouton Rejoindre une partie
        OutlinedButton.icon(
          onPressed: _handleJoinGame,
          icon: const Icon(Icons.group_add),
          label: const Text('Rejoindre une partie'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
