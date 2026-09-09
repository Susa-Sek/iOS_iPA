import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

void main() {
  group('LearningState', () {
    late LearningState state;
    late VocabEntry word;

    setUp(() {
      state = LearningState();
      word = kAllEntries.first;
    });

    test('startet bei Box 0', () {
      expect(state.boxOf(word), 0);
      expect(state.isLearned(word), isFalse);
      expect(state.learnedCount, 0);
    });

    test('richtige Antworten schieben ein Wort bis in die letzte Box', () {
      for (int i = 0; i < LearningState.maxBox; i++) {
        state.promote(word);
      }
      expect(state.boxOf(word), LearningState.maxBox);
      expect(state.isLearned(word), isTrue);
      expect(state.learnedCount, 1);
    });

    test('promote geht nie über die letzte Box hinaus', () {
      for (int i = 0; i < LearningState.maxBox + 5; i++) {
        state.promote(word);
      }
      expect(state.boxOf(word), LearningState.maxBox);
    });

    test('ein Fehler wirft das Wort zurück auf Box 0', () {
      state.promote(word);
      state.promote(word);
      state.demote(word);
      expect(state.boxOf(word), 0);
      expect(state.isLearned(word), isFalse);
    });

    test('toggleLearned schaltet zwischen gelernt und offen um', () {
      state.toggleLearned(word);
      expect(state.isLearned(word), isTrue);
      state.toggleLearned(word);
      expect(state.isLearned(word), isFalse);
    });

    test('trainingOrder stellt schwache Wörter nach vorne', () {
      final List<VocabEntry> pool = kCategories.first.entries;
      final VocabEntry strong = pool[3];
      state.markLearned(strong);

      final List<VocabEntry> order = state.trainingOrder(pool);
      expect(order.length, pool.length);
      expect(order.last.id, strong.id);
      expect(state.boxOf(order.first), 0);
    });

    test('Antworten zählen Treffer und Serie', () {
      state.recordAnswer(correct: true);
      state.recordAnswer(correct: true);
      expect(state.streak, 2);
      expect(state.bestStreak, 2);

      state.recordAnswer(correct: false);
      expect(state.streak, 0);
      expect(state.bestStreak, 2);
      expect(state.answered, 3);
      expect(state.correct, 2);
    });

    test('reset leert alles', () {
      state.markLearned(word);
      state.recordAnswer(correct: true);
      state.reset();
      expect(state.learnedCount, 0);
      expect(state.answered, 0);
      expect(state.streak, 0);
    });
  });
}
