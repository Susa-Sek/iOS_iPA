import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../state/learning_state.dart';
import 'achievements_screen.dart';
import 'home_screen.dart';
import 'knowledge_home.dart';
import 'practice_screen.dart';

/// Das Gerüst der App: unten drei Bereiche, dazwischen wird nur der Inhalt
/// getauscht.
///
/// Vorher lag alles auf der Startseite übereinander — Tagesziel, Level, sieben
/// Übungskacheln und der Lernweg. Das war mit wachsendem Umfang nicht mehr zu
/// überblicken. Jetzt hat jeder Teil seinen Platz: „Lernen" für die tägliche
/// Runde, „Üben" für die Übungen und das Nachschlagen, „Erfolge" für den
/// Fortschritt.
///
/// **„Lernen" sieht je Fach anders aus.** In Arabisch ist das Maß das
/// gelernte Wort und der Weg die Wiederholung; im Wissen ist das Maß das
/// verstandene Thema und der Weg die Lektion. Zwei Fächer, zwei Startseiten —
/// eine gemeinsame hätte beiden nicht gepasst. Der Tagesstoff aus dem Netz
/// steht seit dieser Trennung im Fach Wissen, wo er inhaltlich hingehört.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final int due = state.repetitionsDueIn(state.subject);

    return Scaffold(
      // IndexedStack statt Neuaufbau: Wer in einem Bereich gescrollt hat,
      // findet die Stelle beim Zurückwechseln wieder.
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          if (state.subject == Subject.wissen)
            const KnowledgeHome()
          else
            const HomeScreen(),
          const PracticeScreen(),
          const AchievementsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) => setState(() => _index = index),
        destinations: <Widget>[
          NavigationDestination(
            icon: Badge(
              // Anstehende Wiederholungen — nicht alles, was je fällig war.
              // Auf einer frischen Installation gilt jedes Wort als fällig;
              // die Zahl stünde dann für immer auf 801 und sagte nichts.
              isLabelVisible: due > 0,
              label: Text('$due'),
              child: const Icon(Icons.school_outlined),
            ),
            selectedIcon: const Icon(Icons.school),
            label: 'Lernen',
          ),
          const NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Üben',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Erfolge',
          ),
        ],
      ),
    );
  }
}
