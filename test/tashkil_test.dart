import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/alphabet_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/arabic.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';

/// Words that carry no vowel marks by nature: single letters, particles that
/// are written with one sign, and the article.
const Set<String> _withoutMarks = <String>{'الْ'};

void main() {
  group('Tashkīl im Wortschatz', () {
    test('jede Vokabel ist vokalisiert', () {
      final List<VocabEntry> missing = kAllEntries
          .where((VocabEntry e) => !_withoutMarks.contains(e.arabic))
          .where((VocabEntry e) => !hasTashkil(e.arabic))
          .toList();
      expect(missing, isEmpty,
          reason: 'ohne Zeichen: '
              '${missing.map((VocabEntry e) => "${e.german} (${e.arabic})")}');
    });

    test('jedes arabische Wort ohne Zeichen bleibt lesbar', () {
      for (final VocabEntry entry in kAllEntries) {
        expect(entry.arabicPlain, isNotEmpty, reason: entry.german);
        expect(hasTashkil(entry.arabicPlain), isFalse, reason: entry.german);
      }
    });

    test('auch die Kategorienamen sind vokalisiert', () {
      for (final VocabCategory category in kAllCategories) {
        expect(hasTashkil(category.arabicName), isTrue,
            reason: category.name);
      }
    });

    test('die Zeichenübersicht ist vollständig', () {
      expect(kDiacritics.length, greaterThanOrEqualTo(8));
      for (final ArabicDiacritic mark in kDiacritics) {
        expect(mark.name.trim(), isNotEmpty);
        expect(mark.symbol.trim(), isNotEmpty);
        expect(mark.example.trim(), isNotEmpty);
        expect(mark.hint.trim(), isNotEmpty);
        expect(hasTashkil(mark.arabicName), isTrue, reason: mark.name);
      }
      // Fatḥa, Kasra und Ḍamma müssen dabei sein.
      final List<String> names =
          kDiacritics.map((ArabicDiacritic d) => d.name).toList();
      expect(names, containsAll(<String>['Fatḥa', 'Kasra', 'Ḍamma']));
    });
  });

  group('Zeichen-Hilfsfunktionen', () {
    test('erkennt Zeichen und Buchstaben auseinander', () {
      expect(isArabicMark(0x064E), isTrue); // Fatḥa
      expect(isArabicMark(0x0650), isTrue); // Kasra
      expect(isArabicMark(0x064F), isTrue); // Ḍamma
      expect(isArabicMark(0x0651), isTrue); // Shadda
      expect(isArabicMark(0x0628), isFalse); // Bāʾ
    });

    test('hält Buchstabe und Zeichen zusammen', () {
      expect(arabicLetterUnits('كِتَاب'), <String>['كِ', 'تَ', 'ا', 'ب']);
      expect(arabicLetterUnits('شُكْرًا'),
          <String>['شُ', 'كْ', 'رً', 'ا']);
      // م + د + ر (mit Shadda und Kasra) + س — die Zeichen zählen nicht mit.
      expect(arabicLetterUnits('مُدَرِّس'), <String>['مُ', 'دَ', 'رِّ', 'س']);
    });

    test('entfernt die Zeichen für den Vergleich', () {
      expect(withoutTashkil('كِتَاب'), 'كتاب');
      expect(withoutTashkil('شُكْرًا'), 'شكرا');
      expect(withoutTashkil('كتاب'), 'كتاب');
    });

    test('Suche findet ein Wort mit und ohne Zeichen', () {
      const VocabEntry book = VocabEntry('Buch', 'كِتَاب', 'kitab');
      expect(book.matches('كتاب'), isTrue);
      expect(book.matches('كِتَاب'), isTrue);
      expect(book.matches('kitab'), isTrue);
      expect(book.matches('Buch'), isTrue);
      expect(book.matches('قَمَر'), isFalse);
    });
  });
}
