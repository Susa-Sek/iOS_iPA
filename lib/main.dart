import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/learning_state.dart';

void main() {
  runApp(const ArabischLernenApp());
}

/// "Arabisch lernen" — a small vocabulary trainer for German speakers.
class ArabischLernenApp extends StatefulWidget {
  const ArabischLernenApp({super.key});

  @override
  State<ArabischLernenApp> createState() => _ArabischLernenAppState();
}

class _ArabischLernenAppState extends State<ArabischLernenApp> {
  final LearningState _state = LearningState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F7A6C),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F6F2)
          : scheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LearningScope(
      state: _state,
      child: MaterialApp(
        title: 'Arabisch lernen',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }
}
