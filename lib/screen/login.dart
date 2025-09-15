import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/global_data.dart' as global;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isLoginMode = true; // true = login, false = signup
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://pictioniary.wevox.cloud/api/players'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201) {
        // Inscription réussie
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compte créé avec succès ! Vous pouvez maintenant vous connecter.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Retour au mode connexion
        setState(() {
          _isLoginMode = true;
        });
      } else if (response.statusCode == 409) {
        // Compte existant
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ce nom d\'utilisateur existe déjà. Choisissez-en un autre.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Autre erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'inscription: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://pictioniary.wevox.cloud/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // Connexion réussie
        final responseData = jsonDecode(response.body);

        // Sauvegarder les données globales
        global.username = _usernameController.text.trim();
        global.token = responseData['token'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isLoggedIn = true;
        });
      } else if (response.statusCode == 401) {
        // Identifiants incorrects
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nom d\'utilisateur ou mot de passe incorrect.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 404) {
        // Utilisateur non trouvé
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non trouvé. Veuillez vous inscrire.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Autre erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la connexion: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSubmit() {
    if (_isLoginMode) {
      _handleLogin();
    } else {
      _handleSignup();
    }
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _usernameController.clear();
      _passwordController.clear();
      // Vider les données globales
      global.username = '';
      global.token = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Déconnexion réussie'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleNewGame() {
    Navigator.pushNamed(context, '/new-game');
  }

  void _handleJoinGame() {
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
                              : _buildAuthContent(),
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

  Widget _buildAuthContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle entre Login/Signup
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _isLoginMode ? null : _toggleMode,
                child: Text(
                  'Se connecter',
                  style: TextStyle(
                    color:
                        _isLoginMode
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                    fontWeight:
                        _isLoginMode ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const Text(' | '),
              TextButton(
                onPressed: _isLoginMode ? _toggleMode : null,
                child: Text(
                  'S\'inscrire',
                  style: TextStyle(
                    color:
                        !_isLoginMode
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                    fontWeight:
                        !_isLoginMode ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Titre dynamique
          Text(
            _isLoginMode ? 'Connexion' : 'Inscription',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

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
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // Champ mot de passe
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              hintText: 'Entre ton mot de passe',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un mot de passe';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),

          const SizedBox(height: 24),

          // Bouton principal
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
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
                    : Text(_isLoginMode ? 'Se connecter' : 'S\'inscrire'),
          ),

          const SizedBox(height: 16),

          // Message d'aide
          if (!_isLoginMode)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Créez un compte pour sauvegarder vos statistiques',
                      style: TextStyle(color: Colors.blue[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
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

        // Bouton déconnexion
        TextButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }
}
