import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'theme/app_theme.dart';
import 'state/learning_state.dart';
import 'state/reminders.dart';
import 'state/speech.dart';
import 'widgets/speak_button.dart';

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
  final Speaker _speaker = Speaker();
  final ReminderService _reminders = ReminderService();

  @override
  void initState() {
    super.initState();
    // Reads the saved boxes, streak and statistics from the device …
    _state.load();
    // … and asks the system whether it can speak Arabic at all.
    _speaker.init();
    _setUpReminders();
  }

  /// Bei jedem Start den Erinnerungsplan auffrischen: Ein Tag, an dem das
  /// Ziel schon erreicht ist, bekommt keine Erinnerung mehr.
  Future<void> _setUpReminders() async {
    await _reminders.load();
    if (!_state.isLoaded) await _state.load();
    await _reminders.refresh(
      goalReachedToday: _state.goalReached,
      dueCount: _state.dueCount,
    );
  }

  @override
  void dispose() {
    _state.dispose();
    _speaker.dispose();
    _reminders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScope(
      state: _state,
      child: SpeechScope(
        speaker: _speaker,
        child: ReminderScope(
        service: _reminders,
        child: MaterialApp(
          title: 'Arabisch lernen',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          home: const AppShell(),
        ),
        ),
      ),
    );
  }
}
