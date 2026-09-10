import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/content_registry.dart';
import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';

/// Ein winziger Inhalt, wie ihn ein weiteres Fach mitbringen würde — bewusst
/// ohne ein einziges arabisches Zeichen.
const VocabCategory _wissen = VocabCategory(
  id: 'test_wissen',
  name: 'Testwissen',
  icon: Icons.lightbulb_outline,
  color: Color(0xFF333333),
  softColor: Color(0x24333333),
  script: TextScript.latin,
  entries: <VocabEntry>[
    VocabEntry.fact('Wolga', 'Längster Fluss Europas'),
    VocabEntry.fact('Everest', 'Höchster Berg der Erde'),
    VocabEntry.question(
      'Wie viele Bundesländer hat Deutschland?',
      '16',
      distractors: <String>['12', '14', '18'],
      explanation: 'Seit der Wiedervereinigung 1990.',
    ),
  ],
);

const CategoryGroup _gruppe = CategoryGroup(
  id: 'test_gruppe',
  name: 'Testbereich',
  description: 'Nur für den Test.',
  icon: Icons.science_outlined,
  categories: <VocabCategory>[_wissen],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Registry', () {
    test('die App-Registry führt Wortschatz und Wissen zusammen', () {
      const ContentRegistry content = AppContent();
      expect(content.entries.length,
          kAllEntries.length + kKnowledgeEntries.length);
      expect(content.categories.length,
          kAllCategories.length + kKnowledgeCategories.length);
      expect(content.groups, isNotEmpty);
      // Aus beiden Fächern je ein Thema.
      expect(content.categoryById('allgemein'), isNotNull);
      expect(content.categoryById('w_geografie'), isNotNull);
      expect(content.categoryById('gibtsnicht'), isNull);
    });

    test('Wissen wird nicht in den arabischen Bestand gemischt', () {
      // Der Datentest fordert für jeden Eintrag in kAllEntries arabische
      // Schrift. Diese Grenze muss halten, auch wenn Fächer dazukommen.
      for (final VocabEntry entry in kAllEntries) {
        expect(entry.isLanguage, isTrue, reason: entry.german);
      }
    });

    test('gleicher Schlüssel heißt auch gleiches Wort', () {
      // Manche Wörter stehen in zwei Themen — "Flughafen" gehört zu Reise
      // und zu Orte. Sie teilen sich den Speicher-Schlüssel, und das ist
      // richtig: Wer das Wort einmal kann, kann es überall. Falsch wäre nur,
      // wenn zwei *verschiedene* Inhalte denselben Schlüssel bekämen — dann
      // würde ein Lernstand einen fremden überschreiben.
      final Map<String, VocabEntry> seen = <String, VocabEntry>{};
      for (final VocabEntry entry in kAllEntries) {
        final VocabEntry? other = seen[entry.id];
        if (other == null) {
          seen[entry.id] = entry;
          continue;
        }
        expect(other.german, entry.german, reason: entry.id);
        expect(other.arabic, entry.arabic, reason: entry.id);
        expect(other.transliteration, entry.transliteration, reason: entry.id);
      }
    });

    test('Wissenskarten kollidieren nicht mit dem Wortschatz', () {
      final Set<String> vocabularyIds =
          kAllEntries.map((VocabEntry e) => e.id).toSet();
      for (final VocabEntry entry in _wissen.entries) {
        expect(vocabularyIds.contains(entry.id), isFalse,
            reason: 'Wissenskarte überschreibt Vokabel: ${entry.id}');
      }
    });
  });

  group('Lernkern mit fremdem Inhalt', () {
    test('rechnet mit dem, was die Registry liefert', () async {
      final LearningState state = LearningState(
        store: ProgressStore(),
        content: const FixedContent(<CategoryGroup>[_gruppe]),
        clock: () => DateTime(2026, 5, 1, 9),
      );
      await state.load();

      expect(state.totalCount, 3);
      expect(state.dueCount, 3);
      expect(state.learnedCount, 0);

      state.markLearned(_wissen.entries.first);
      expect(state.learnedCount, 1);
      expect(state.progressOf(_wissen), closeTo(1 / 3, 0.001));
      expect(state.learnedInGroup(_gruppe), 1);
      expect(state.progressOfGroup(_gruppe), closeTo(1 / 3, 0.001));
    });

    test('das Quran-Abzeichen bleibt ohne Quran-Kategorie ruhig', () async {
      final LearningState state = LearningState(
        store: ProgressStore(),
        content: const FixedContent(<CategoryGroup>[_gruppe]),
        clock: () => DateTime(2026, 5, 1, 9),
      );
      await state.load();
      for (final VocabEntry entry in _wissen.entries) {
        state.markLearned(entry);
      }
      expect(state.achievementStats.learnedQuranWords, 0);
      // Ein vollständig gelerntes Thema zählt trotzdem.
      expect(state.achievementStats.completedCategories, 1);
    });

    test('Fortschritt je Bereich statt einer Zahl über alles', () async {
      final LearningState state = LearningState(
        store: ProgressStore(),
        clock: () => DateTime(2026, 5, 1, 9),
      );
      await state.load();
      final CategoryGroup first = state.content.groups.first;
      expect(state.progressOfGroup(first), 0);
      state.markLearned(first.entries.first);
      expect(state.progressOfGroup(first), greaterThan(0));
      expect(state.dueInGroup(first), first.entries.length - 1);
    });
  });
}
