import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';

/// Das Datenmodell wurde für Wissensinhalte geöffnet. Diese Tests halten
/// fest, was dabei nicht kaputtgehen darf — vor allem der Schlüssel, unter
/// dem der Lernstand auf dem Gerät liegt.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Abwärtskompatibilität', () {
    test('der Schlüssel eines Eintrags bleibt "deutsch|antwort"', () {
      const VocabEntry entry = VocabEntry('Buch', 'كِتَاب', 'kitab');
      expect(entry.id, 'Buch|كِتَاب');
    });

    test('neue Felder ändern den Schlüssel nicht', () {
      const VocabEntry plain = VocabEntry('Buch', 'كِتَاب', 'kitab');
      const VocabEntry rich = VocabEntry(
        'Buch',
        'كِتَاب',
        'kitab',
        explanation: 'Kommt von der Wurzel ك-ت-ب.',
        source: 'Grundwortschatz',
      );
      expect(rich.id, plain.id);
    });

    test('ein vor dem Umbau gespeicherter Fortschritt wird wiedergefunden',
        () async {
      final VocabEntry word = kAllEntries.first;
      final DateTime now = DateTime(2026, 5, 1, 9);

      // Speicherstand, wie ihn eine ältere Version geschrieben hätte.
      final LearningState before =
          LearningState(store: ProgressStore(), clock: () => now);
      await before.load();
      before.promote(word);
      before.promote(word);
      final int box = before.boxOf(word);

      final LearningState after =
          LearningState(store: ProgressStore(), clock: () => now);
      await after.load();
      expect(after.boxOf(word), box);
      expect(after.boxOf(word), 2);
    });

    test('alte Aufrufe bleiben gültig und ohne Zusatzfelder', () {
      const VocabEntry entry = VocabEntry('danke', 'شُكْرًا', 'shukran');
      expect(entry.distractors, isEmpty);
      expect(entry.explanation, isNull);
      expect(entry.question, isNull);
      expect(entry.script, TextScript.arabic);
      expect(entry.isLanguage, isTrue);
      expect(entry.prompt, 'danke');
      expect(entry.answer, 'شُكْرًا');
    });
  });

  group('Wissenskarten', () {
    test('eine Begriffskarte hat keine Lautschrift und läuft von links', () {
      const VocabEntry fact = VocabEntry.fact(
        'Inflation',
        'Anhaltender Anstieg des allgemeinen Preisniveaus',
        explanation: 'Für dasselbe Geld bekommt man weniger.',
      );
      expect(fact.transliteration, isEmpty);
      expect(fact.script, TextScript.latin);
      expect(fact.isLanguage, isFalse);
      expect(fact.prompt, 'Inflation');
      expect(fact.explanation, isNotNull);
    });

    test('eine Frage bringt ihre Falschantworten mit', () {
      const VocabEntry question = VocabEntry.question(
        'Wer wählt den Bundeskanzler?',
        'Der Bundestag',
        distractors: <String>[
          'Das Volk direkt',
          'Der Bundesrat',
          'Der Bundespräsident',
        ],
        explanation: 'Artikel 63 Grundgesetz.',
      );
      expect(question.distractors.length, 3);
      expect(question.prompt, 'Wer wählt den Bundeskanzler?');
      expect(question.answer, 'Der Bundestag');
      expect(question.distractors, isNot(contains(question.answer)));
    });

    test('die Suche findet auch über die Erklärung', () {
      const VocabEntry fact = VocabEntry.fact(
        'Inflation',
        'Anstieg des Preisniveaus',
        explanation: 'Für dasselbe Geld bekommt man weniger Ware.',
      );
      expect(fact.matches('Ware'), isTrue);
      expect(fact.matches('Preisniveaus'), isTrue);
      expect(fact.matches('Photosynthese'), isFalse);
    });
  });
}
