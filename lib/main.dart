import 'package:flutter/material.dart';

import 'data/content_registry.dart';
import 'data/knowledge/knowledge_data.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';
import 'state/custom_cards.dart';
import 'state/daily_feed.dart';
import 'state/learning_state.dart';
import 'state/daily_quests.dart';
import 'state/duel_store.dart';
import 'state/lesson_store.dart';
import 'state/reward_store.dart';
import 'state/sharing.dart';
import 'state/reminders.dart';
import 'state/speech.dart';
import 'widgets/speak_button.dart';

void main() {
  runApp(const TaeglichKluegerApp());
}

/// „Täglich Klüger" — Arabisch und Allgemeinwissen in einer App.
///
/// Der Paketname `de.susasek.arabischlernen` und der Dart-Paketname
/// bleiben, wie sie sind: Sie sind kein Anzeigename, sondern die
/// Identität der Installation. Ein anderer Paketname hieße für jedes
/// Gerät: neue App, kein Lernstand.
class TaeglichKluegerApp extends StatefulWidget {
  const TaeglichKluegerApp({super.key});

  @override
  State<TaeglichKluegerApp> createState() => _TaeglichKluegerAppState();
}

class _TaeglichKluegerAppState extends State<TaeglichKluegerApp> {
  final CustomCardStore _cards = CustomCardStore();
  late final LearningState _state = LearningState(
    content: ContentWithCustomCards(kDefaultContent, _cards),
  );
  final Speaker _speaker = Speaker();
  final ReminderService _reminders = ReminderService();
  final DailyFeedService _feed = DailyFeedService();
  final LessonStore _lessons = LessonStore();
  final RewardStore _rewards = RewardStore();
  final DuelStore _duels = DuelStore();
  final Sharer _sharer = Sharer();

  @override
  void initState() {
    super.initState();
    // Eine gemerkte Karte ändert den Vorrat — die Startseite muss das sehen,
    // ohne dass die App neu gestartet wird.
    _cards.addListener(_state.contentChanged);
    _cards.load();
    // Reads the saved boxes, streak and statistics from the device …
    _state.load();
    // … and asks the system whether it can speak Arabic at all.
    _speaker.init();
    // Der Tagesinhalt wird nur aus dem Speicher gelesen; geholt wird er erst,
    // wenn jemand den Bereich „Heute" öffnet.
    _feed.load();
    // Die Abzeichen fürs Wissen zählen Lektionen; der Lernkern erfährt den
    // Stand, statt den Speicher zu kennen.
    _lessons.addListener(_meldeLektionen);
    _lessons.load().then((_) => _meldeLektionen());
    // Jede Antwort läuft durch den Lernkern; von dort aus zählen die
    // Tagesaufgaben mit, ohne dass acht Übungsbildschirme davon wissen.
    _state.attachQuests(
        (QuestKind kind, int amount) => _rewards.report(kind, amount: amount));
    _rewards.load();
    _duels.load();
    _setUpReminders();
  }

  /// Bei jedem Start den Erinnerungsplan auffrischen: Ein Tag, an dem das
  /// Ziel schon erreicht ist, bekommt keine Erinnerung mehr.
  Future<void> _setUpReminders() async {
    await _reminders.load();
    if (!_state.isLoaded) await _state.load();
    await _reminders.refresh(
      goalReachedToday: _state.goalReached,
      // Über beide Fächer: Die Erinnerung soll an das ganze Pensum
      // erinnern, nicht nur an das gerade gewählte Fach.
      dueCount: _state.dueCountTotal,
    );
  }

  void _meldeLektionen() => _state.reportLessons(
        done: _lessons.doneCount,
        topicsUnderstood: _lessons.understoodIn(kKnowledgeCategories),
      );

  @override
  void dispose() {
    _lessons.removeListener(_meldeLektionen);
    _rewards.dispose();
    _duels.dispose();
    _cards.removeListener(_state.contentChanged);
    _cards.dispose();
    _feed.dispose();
    _lessons.dispose();
    _state.dispose();
    _speaker.dispose();
    _reminders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScope(
      state: _state,
      child: CustomCardScope(
        store: _cards,
        child: LessonScope(
          store: _lessons,
          child: RewardScope(
          store: _rewards,
          child: DuelScope(
          store: _duels,
          child: ShareScope(
          sharer: _sharer,
          child: DailyFeedScope(
          service: _feed,
          child: SpeechScope(
            speaker: _speaker,
            child: ReminderScope(
              service: _reminders,
              child: MaterialApp(
                title: 'Täglich Klüger',
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(Brightness.light),
                darkTheme: buildAppTheme(Brightness.dark),
                home: const AppShell(),
              ),
            ),
          ),
        ),
        ),
        ),
        ),
        ),
      ),
    );
  }
}
