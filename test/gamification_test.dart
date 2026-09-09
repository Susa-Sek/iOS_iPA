import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/achievements_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/achievement.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  LearningState stateAt(DateTime now) =>
      LearningState(store: ProgressStore(), clock: () => now);

  group('Punkte und Level', () {
    test('richtige Antworten geben mehr Punkte als falsche', () async {
      final LearningState state = stateAt(DateTime(2026, 5, 1, 9));
      await state.load();
      await state.setDailyGoal(100); // Zielbonus hier ausklammern

      state.recordAnswer(correct: true);
      expect(state.xp, LearningState.xpPerCorrect);

      state.recordAnswer(correct: false);
      expect(state.xp, LearningState.xpPerCorrect + LearningState.xpPerWrong);
    });

    test('das erreichte Tagesziel gibt einmalig Bonuspunkte', () async {
      final LearningState state = stateAt(DateTime(2026, 5, 1, 9));
      await state.load();
      await state.setDailyGoal(2);

      state.recordAnswer(correct: true);
      state.recordAnswer(correct: true);
      expect(state.goalReached, isTrue);
      expect(state.xp, 2 * LearningState.xpPerCorrect + LearningState.xpPerGoal);
      expect(state.goalDays, 1);

      // Weitere Antworten am selben Tag geben den Bonus nicht noch einmal.
      state.recordAnswer(correct: true);
      expect(state.goalDays, 1);
      expect(state.xp,
          3 * LearningState.xpPerCorrect + LearningState.xpPerGoal);
    });

    test('das Level wächst mit den Punkten', () async {
      final LearningState state = stateAt(DateTime(2026, 5, 1, 9));
      await state.load();
      await state.setDailyGoal(1000);

      expect(state.level, 1);
      for (int i = 0; i < 10; i++) {
        state.recordAnswer(correct: true); // 100 Punkte
      }
      expect(state.level, 2);
      expect(state.xpForNextLevel, 400);

      for (int i = 0; i < 30; i++) {
        state.recordAnswer(correct: true); // insgesamt 400
      }
      expect(state.level, 3);
      expect(state.levelProgress, 0);
    });

    test('Punkte und perfekte Runden überstehen einen Neustart', () async {
      final DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState first = stateAt(now);
      await first.load();
      first.recordAnswer(correct: true);
      first.recordPerfectRound();
      final int xp = first.xp;

      final LearningState second = stateAt(now);
      await second.load();
      expect(second.xp, xp);
      expect(second.perfectRounds, 1);
    });

    test('Zurücksetzen löscht auch Punkte und Abzeichen', () async {
      final DateTime now = DateTime(2026, 5, 1, 9);
      final LearningState state = stateAt(now);
      await state.load();
      state.recordAnswer(correct: true);
      state.recordPerfectRound();

      await state.reset();
      expect(state.xp, 0);
      expect(state.perfectRounds, 0);
      expect(state.level, 1);
      expect(state.unlockedAchievements, isEmpty);
    });
  });

  group('Abzeichen', () {
    test('am Anfang ist keines freigeschaltet', () async {
      final LearningState state = stateAt(DateTime(2026, 5, 1, 9));
      await state.load();
      expect(state.unlockedAchievements, isEmpty);
    });

    test('zehn gelernte Wörter schalten das erste Abzeichen frei', () async {
      final LearningState state = stateAt(DateTime(2026, 5, 1, 9));
      await state.load();
      for (final VocabEntry entry in kAllEntries.take(10)) {
        state.markLearned(entry);
      }
      expect(
        state.unlockedAchievements.map((Achievement a) => a.id),
        contains('first_ten'),
      );
    });

    test('ein komplett gelerntes Thema zählt', () async {
      final LearningState state = stateAt(DateTime(2026, 5, 1, 9));
      await state.load();
      final VocabCategory category = kAllCategories
          .reduce((VocabCategory a, VocabCategory b) =>
              a.entries.length <= b.entries.length ? a : b);
      for (final VocabEntry entry in category.entries) {
        state.markLearned(entry);
      }
      expect(state.achievementStats.completedCategories, greaterThanOrEqualTo(1));
      expect(
        state.unlockedAchievements.map((Achievement a) => a.id),
        contains('category_done'),
      );
    });

    test('eine perfekte Runde schaltet "Fehlerfrei" frei', () async {
      final LearningState state = stateAt(DateTime(2026, 5, 1, 9));
      await state.load();
      state.recordPerfectRound();
      expect(
        state.unlockedAchievements.map((Achievement a) => a.id),
        contains('perfect_round'),
      );
    });

    test('jedes Abzeichen hat Text, Ziel und eindeutige id', () {
      final Set<String> ids = <String>{};
      for (final Achievement a in kAchievements) {
        expect(ids.add(a.id), isTrue, reason: 'doppelt: ${a.id}');
        expect(a.name.trim(), isNotEmpty);
        expect(a.description.trim(), isNotEmpty, reason: a.id);
        expect(a.target, greaterThan(0), reason: a.id);
      }
      expect(kAchievements.length, greaterThanOrEqualTo(10));
    });
  });
}
