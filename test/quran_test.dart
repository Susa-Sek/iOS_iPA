import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/quran_data.dart';
import 'package:ipa_testing_github_action/data/quran_vocab.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/models/arabic.dart';
import 'package:ipa_testing_github_action/models/quran.dart';

/// The verses as they came from the source, kept next to the test so the
/// claim "the text is not typed by hand" stays checkable.
Map<String, dynamic> loadReference() {
  final File file = File('test/data/quran_reference.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  final Map<String, dynamic> reference = loadReference();
  final Map<String, dynamic> suras =
      reference['suras'] as Map<String, dynamic>;

  group('Quran-Text', () {
    test('jeder Vers stimmt Zeichen für Zeichen mit der Quelle überein', () {
      for (final QuranSura sura in kSuras) {
        final Map<String, dynamic> source =
            suras['${sura.number}'] as Map<String, dynamic>;
        final Map<String, dynamic> ayahs =
            source['ayahs'] as Map<String, dynamic>;

        expect(sura.verses.length, ayahs.length,
            reason: 'Sure ${sura.number}: Verszahl');

        for (final QuranVerse verse in sura.verses) {
          String expected = (ayahs['${verse.number}'] as String).trim();
          // Bei allen Suren außer al-Fātiḥa steht die Basmala der Quelle vor
          // Vers 1; in der App ist sie eine eigene Zeile.
          if (sura.opensWithBasmala && verse.number == 1) {
            expect(expected.startsWith(kBasmala.arabic), isTrue,
                reason: 'Sure ${sura.number}: Basmala erwartet');
            expected = expected.substring(kBasmala.arabic.length).trim();
          }
          expect(verse.arabic, expected,
              reason: 'Sure ${sura.number}, Vers ${verse.number}');
        }
      }
    });

    test('die Suren sind vollständig und vokalisiert', () {
      expect(kSuras.length, 6);
      final Map<int, int> expectedVerses = <int, int>{
        1: 7, 103: 3, 108: 3, 112: 4, 113: 5, 114: 6,
      };
      for (final QuranSura sura in kSuras) {
        expect(sura.verseCount, expectedVerses[sura.number],
            reason: sura.name);
        for (final QuranVerse verse in sura.verses) {
          expect(hasTashkil(verse.arabic), isTrue,
              reason: '${sura.name} ${verse.number}');
        }
      }
    });

    test('jedes Wort hat Lautschrift und Bedeutung', () {
      for (final QuranSura sura in kSuras) {
        for (final QuranVerse verse in sura.verses) {
          expect(verse.words, isNotEmpty);
          expect(verse.german.trim(), isNotEmpty);
          for (final QuranWord word in verse.words) {
            expect(word.arabic.trim(), isNotEmpty);
            expect(word.transliteration.trim(), isNotEmpty,
                reason: word.arabic);
            expect(word.german.trim(), isNotEmpty, reason: word.arabic);
            // Ein Wort, kein halber Vers.
            expect(word.arabic.contains(' '), isFalse, reason: word.arabic);
          }
        }
      }
    });

    test('die Basmala ist vollständig erfasst', () {
      expect(kBasmala.words.length, 4);
      expect(kBasmala.arabic.split(' ').length, 4);
      expect(hasTashkil(kBasmala.arabic), isTrue);
    });
  });

  group('Quran-Wortschatz', () {
    test('100 Wortformen, alle vokalisiert und eindeutig', () {
      expect(kQuranWords.entries.length, 100);

      final Set<String> arabic = <String>{};
      final Set<String> german = <String>{};
      for (final VocabEntry entry in kQuranWords.entries) {
        expect(hasTashkil(entry.arabic), isTrue, reason: entry.german);
        expect(arabic.add(entry.arabic), isTrue,
            reason: 'doppelt: ${entry.arabic}');
        expect(german.add(entry.german), isTrue,
            reason: 'doppelt: ${entry.german}');
      }
    });

    test('die häufigsten Wörter kommen auch in den Suren vor', () {
      // Eine Stichprobe: was oben in der Häufigkeitsliste steht, muss im
      // Text der kurzen Suren auftauchen.
      final Set<String> inSuras = <String>{
        for (final QuranSura sura in kSuras)
          for (final QuranVerse verse in sura.verses)
            for (final QuranWord word in verse.words)
              withoutTashkil(word.arabic),
      };
      for (final String word in <String>['قل', 'الله', 'من', 'ما', 'هو']) {
        expect(inSuras, contains(word), reason: word);
      }
    });
  });

  group('Wurzeln', () {
    test('jede Wurzel hat Bedeutung und mehrere Ableitungen', () {
      expect(kRoots.length, greaterThanOrEqualTo(10));
      for (final ArabicRoot root in kRoots) {
        expect(root.letters.trim(), isNotEmpty);
        expect(root.meaning.trim(), isNotEmpty, reason: root.letters);
        expect(root.derivations.length, greaterThanOrEqualTo(3),
            reason: root.letters);
        for (final QuranWord word in root.derivations) {
          expect(hasTashkil(word.arabic), isTrue, reason: word.arabic);
          expect(word.german.trim(), isNotEmpty, reason: word.arabic);
        }
      }
    });
  });
}
