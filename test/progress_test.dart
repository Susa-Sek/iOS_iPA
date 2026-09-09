import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/word_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VocabEntry word;
  late VocabEntry other;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    word = kAllEntries.first;
    other = kAllEntries[5];
  });

  /// A state whose clock the test controls, so schedules can be checked
  /// without waiting for real days to pass.
  LearningState stateAt(DateTime Function() clock) =>
      LearningState(store: ProgressStore(), clock: clock);

  group('Wiederholungstermine', () {
    test('ein neues Wort ist sofort fällig', () async {
      final LearningState state = stateAt(() => DateTime(2026, 5, 1));
      await state.load();
      expect(state.isDue(word), isTrue);
      expect(state.dueCount, state.totalCount);
    });

    test('richtige Antworten schieben den Termin weiter', () async {
      DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState state = stateAt(() => now);
      await state.load();

      state.promote(word); // Stufe 1 → in 1 Tag
      expect(state.boxOf(word), 1);
      expect(state.isDue(word), isFalse);

      now = DateTime(2026, 5, 2, 9);
      expect(state.isDue(word), isTrue);

      state.promote(word); // Stufe 2 → in 3 Tagen
      expect(state.boxOf(word), 2);
      now = DateTime(2026, 5, 4, 9);
      expect(state.isDue(word), isFalse);
      now = DateTime(2026, 5, 5, 9);
      expect(state.isDue(word), isTrue);
    });

    test('ein Fehler holt das Wort auf heute zurück', () async {
      DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState state = stateAt(() => now);
      await state.load();

      state.promote(word);
      state.promote(word);
      state.promote(word);
      expect(state.isLearned(word), isTrue);

      state.demote(word);
      expect(state.boxOf(word), 0);
      expect(state.isLearned(word), isFalse);
      expect(state.isDue(word), isTrue);
    });

    test('die Stufe wächst nicht über das Maximum hinaus', () async {
      final LearningState state = stateAt(() => DateTime(2026, 5, 1));
      await state.load();
      for (int i = 0; i < LearningState.maxBox + 5; i++) {
        state.promote(word);
      }
      expect(state.boxOf(word), LearningState.maxBox);
    });

    test('fällige Wörter kommen in der Übung zuerst', () async {
      DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState state = stateAt(() => now);
      await state.load();

      final List<VocabEntry> pool = kCategories.first.entries;
      state.promote(pool[2]); // erst morgen wieder fällig
      now = DateTime(2026, 5, 1, 18);

      final List<VocabEntry> order = state.trainingOrder(pool);
      expect(order.length, pool.length);
      expect(order.last.id, pool[2].id);
      expect(state.isDue(order.first), isTrue);
    });
  });

  group('Speichern', () {
    test('der Lernstand überlebt einen Neustart', () async {
      final DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState first = stateAt(() => now);
      await first.load();
      first.promote(word);
      first.promote(word);
      first.demote(other);
      first.recordAnswer(correct: true);
      await first.setDailyGoal(20);

      // Neue Instanz — wie ein Neustart der App.
      final LearningState second = stateAt(() => now);
      await second.load();

      expect(second.boxOf(word), 2);
      expect(second.boxOf(other), 0);
      expect(second.dueDateOf(word), first.dueDateOf(word));
      expect(second.answered, 1);
      expect(second.correct, 1);
      expect(second.dailyGoal, 20);
      expect(second.answeredToday, 1);
    });

    test('Zurücksetzen leert auch den Speicher', () async {
      final DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState first = stateAt(() => now);
      await first.load();
      first.markLearned(word);
      first.recordAnswer(correct: true);
      await first.reset();

      final LearningState second = stateAt(() => now);
      await second.load();
      expect(second.learnedCount, 0);
      expect(second.answered, 0);
      expect(second.answeredToday, 0);
    });

    test('ein beschädigter Speicher startet leer statt zu stürzen', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ProgressStore.storageKey: 'kein json {{{',
      });
      final LearningState state = stateAt(() => DateTime(2026, 5, 1));
      await state.load();
      expect(state.learnedCount, 0);
      expect(state.isLoaded, isTrue);
    });

    test('kodieren und dekodieren erhält die Daten', () {
      final StoredProgress original = StoredProgress(
        words: <String, WordProgress>{
          'a|ا': WordProgress(
            box: 3,
            due: DateTime(2026, 6, 1),
            lastAnswered: DateTime(2026, 5, 25),
          ),
        },
        answered: 42,
        correct: 30,
        bestStreak: 7,
        dailyGoal: 15,
        history: const <String, int>{'2026-05-25': 12},
      );

      final StoredProgress back =
          ProgressStore.decode(ProgressStore.encode(original));

      expect(back.answered, 42);
      expect(back.correct, 30);
      expect(back.bestStreak, 7);
      expect(back.dailyGoal, 15);
      expect(back.history['2026-05-25'], 12);
      expect(back.words['a|ا']!.box, 3);
      expect(back.words['a|ا']!.due, DateTime(2026, 6, 1));
    });
  });

  group('Tagesziel und Serie', () {
    test('das Tagesziel zählt die Antworten des Tages', () async {
      DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState state = stateAt(() => now);
      await state.load();
      await state.setDailyGoal(3);

      state.recordAnswer(correct: true);
      state.recordAnswer(correct: false);
      expect(state.answeredToday, 2);
      expect(state.goalReached, isFalse);

      state.recordAnswer(correct: true);
      expect(state.goalReached, isTrue);
      expect(state.dayStreak, 1);

      // Am nächsten Tag beginnt die Zählung neu, die Serie bleibt.
      now = DateTime(2026, 5, 2, 9);
      expect(state.answeredToday, 0);
      expect(state.goalReached, isFalse);
      expect(state.dayStreak, 1);
    });

    test('eine Lücke beendet die Serie', () async {
      DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState state = stateAt(() => now);
      await state.load();
      await state.setDailyGoal(1);

      state.recordAnswer(correct: true);
      now = DateTime(2026, 5, 2, 9);
      state.recordAnswer(correct: true);
      expect(state.dayStreak, 2);

      // 3. Mai ausgelassen, am 4. wieder geübt.
      now = DateTime(2026, 5, 4, 9);
      state.recordAnswer(correct: true);
      expect(state.dayStreak, 1);
    });

    test('die Aktivität der letzten Tage wird geliefert', () async {
      DateTime now = DateTime(2026, 5, 10, 9);
      final LearningState state = stateAt(() => now);
      await state.load();
      state.recordAnswer(correct: true);
      state.recordAnswer(correct: true);

      final List<MapEntry<DateTime, int>> activity =
          state.recentActivity(days: 7);
      expect(activity.length, 7);
      expect(activity.last.key, DateTime(2026, 5, 10));
      expect(activity.last.value, 2);
      expect(activity.first.value, 0);
    });
  });
}
