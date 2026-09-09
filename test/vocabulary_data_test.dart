import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/alphabet_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/build_word_screen.dart';

/// At least one real Arabic letter …
final RegExp _arabicLetter = RegExp(r'[\u0621-\u064A]');

/// … and no Latin letters, apart from the placeholder "X" used in phrases
/// such as "Ich bin X Jahre alt".
final RegExp _latinLetter = RegExp(r'[A-WYZa-wyz]');

void main() {
  group('Vokabeldaten', () {
    test('jede Kategorie hat Wörter und eine eindeutige id', () {
      final Set<String> ids = <String>{};
      for (final VocabCategory category in kCategories) {
        expect(category.entries, isNotEmpty, reason: category.name);
        expect(ids.add(category.id), isTrue, reason: 'doppelt: ${category.id}');
      }
    });

    test('kein Feld ist leer', () {
      for (final VocabEntry entry in kAllEntries) {
        expect(entry.german.trim(), isNotEmpty);
        expect(entry.arabic.trim(), isNotEmpty);
        expect(entry.transliteration.trim(), isNotEmpty);
      }
    });

    test('die arabische Spalte enthält arabische Schrift', () {
      for (final VocabEntry entry in kAllEntries) {
        expect(_arabicLetter.hasMatch(entry.arabic), isTrue,
            reason: '${entry.german}: ${entry.arabic}');
        expect(_latinLetter.hasMatch(entry.arabic), isFalse,
            reason: '${entry.german}: ${entry.arabic}');
      }
    });

    test('innerhalb einer Kategorie kommt kein deutsches Wort doppelt vor', () {
      for (final VocabCategory category in kCategories) {
        final Set<String> seen = <String>{};
        for (final VocabEntry entry in category.entries) {
          expect(seen.add(entry.german), isTrue,
              reason: '${category.name}: ${entry.german}');
        }
      }
    });

    test('es gibt genug Wörter für eine Quizrunde', () {
      expect(kAllEntries.length, greaterThan(100));
      for (final VocabCategory category in kCategories) {
        expect(category.entries.length, greaterThanOrEqualTo(4),
            reason: category.name);
      }
    });

    test('jede Kategorie hat Wörter zum Buchstabenbauen', () {
      for (final VocabCategory category in kCategories) {
        final int suitable =
            category.entries.where(BuildWordScreen.isSuitable).length;
        expect(suitable, greaterThan(0), reason: category.name);
      }
    });
  });

  group('Alphabet', () {
    test('hat 28 Buchstaben', () {
      expect(kAlphabet.length, 28);
    });

    test('jeder Buchstabe hat alle Formen und einen Hinweis', () {
      for (final ArabicLetter letter in kAlphabet) {
        expect(letter.isolated.trim(), isNotEmpty, reason: letter.name);
        expect(letter.initial.trim(), isNotEmpty, reason: letter.name);
        expect(letter.medial.trim(), isNotEmpty, reason: letter.name);
        expect(letter.finalForm.trim(), isNotEmpty, reason: letter.name);
        expect(letter.hint.trim(), isNotEmpty, reason: letter.name);
      }
    });

    test('die Buchstaben sind eindeutig', () {
      final Set<String> seen = <String>{};
      for (final ArabicLetter letter in kAlphabet) {
        expect(seen.add(letter.isolated), isTrue, reason: letter.name);
      }
    });
  });
}
