import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pictionary Game',
      theme: ThemeData(
        // Palette de couleurs ludique et créative
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF), // Violet moderne
          brightness: Brightness.light,
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFFFF6B6B), // Rouge corail
          tertiary: const Color(0xFF4ECDC4), // Turquoise
          surface: const Color(0xFFF8F9FA),
          background: const Color(0xFFF8F9FA),
          error: const Color(0xFFE74C3C),
        ),

        // Configuration de l'AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // Boutons élevés (pour les actions principales)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Boutons outline (pour les actions secondaires)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
            side: const BorderSide(color: Color(0xFF6C63FF), width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // FloatingActionButton
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4ECDC4),
          foregroundColor: Colors.white,
          elevation: 6,
        ),

        // Cards
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),

        // Champs de texte
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF666666)),
          hintStyle: const TextStyle(color: Color(0xFF999999)),
        ),

        // Typographie
        textTheme: const TextTheme(
          // Titre principal
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
          // Sous-titres
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
          // Titre de section
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
          // Texte du corps
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF2C3E50),
            height: 1.5,
          ),
          // Étiquettes
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),

        // Icônes
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF), size: 24),

        // Diviseurs
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
          space: 16,
        ),

        // Couleurs personnalisées pour les alertes/scores
        extensions: const <ThemeExtension<dynamic>>[
          GameColorsExtension(
            success: Color(0xFF27AE60),
            warning: Color(0xFFF39C12),
            info: Color(0xFF3498DB),
            correct: Color(0xFF2ECC71),
            incorrect: Color(0xFFE74C3C),
            neutral: Color(0xFF95A5A6),
          ),
        ],
      ),
      home: const MyHomePage(title: 'Pictionary Game'),
    );
  }
}

// Extension pour les couleurs spécifiques au jeu
class GameColorsExtension extends ThemeExtension<GameColorsExtension> {
  const GameColorsExtension({
    required this.success,
    required this.warning,
    required this.info,
    required this.correct,
    required this.incorrect,
    required this.neutral,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color correct;
  final Color incorrect;
  final Color neutral;

  @override
  GameColorsExtension copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? correct,
    Color? incorrect,
    Color? neutral,
  }) {
    return GameColorsExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  GameColorsExtension lerp(
    ThemeExtension<GameColorsExtension>? other,
    double t,
  ) {
    if (other is! GameColorsExtension) {
      return this;
    }
    return GameColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      correct: Color.lerp(correct, other.correct, t)!,
      incorrect: Color.lerp(incorrect, other.incorrect, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

// Votre classe MyHomePage reste identique
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Exemple d'utilisation des couleurs personnalisées
    final gameColors = Theme.of(context).extension<GameColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Score:', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '$_counter',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: gameColors.success),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _incrementCounter,
              child: const Text('Nouveau point'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Ajouter un point',
        child: const Icon(Icons.add),
      ),
    );
  }
}
