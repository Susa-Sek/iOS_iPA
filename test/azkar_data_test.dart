import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/azkar_data.dart';
import 'package:ipa_testing_github_action/data/quran_data.dart';
import 'package:ipa_testing_github_action/models/azkar.dart';
import 'package:ipa_testing_github_action/models/quran.dart';

void main() {
  group('Jeder Eintrag ist vollständig', () {
    test('Quelle, Lautschrift, deutsche Zeile, Anzahl', () {
      // Eine Quelle ist keine Zier: Ohne sie lässt sich ein Text nicht
      // nachschlagen und nicht korrigieren.
      for (final Dhikr d in kAzkar) {
        expect(d.id, isNotEmpty);
        expect(d.arabic.trim(), isNotEmpty, reason: d.id);
        expect(d.transliteration.trim(), isNotEmpty, reason: d.id);
        expect(d.german.trim(), isNotEmpty, reason: d.id);
        expect(d.source.trim(), isNotEmpty, reason: d.id);
        expect(d.count, greaterThanOrEqualTo(1), reason: d.id);
        expect(d.times, isNotEmpty, reason: d.id);
      }
    });

    test('die Kennungen sind eindeutig', () {
      // Sie stehen im Tagesstand — zwei gleiche hießen: ein Dhikr hakt das
      // andere mit ab.
      final List<String> ids = kAzkar.map((Dhikr d) => d.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('der arabische Text trägt keine lateinischen Buchstaben', () {
      for (final Dhikr d in kAzkar) {
        expect(RegExp(r'[A-Za-z]').hasMatch(d.arabic), isFalse, reason: d.id);
      }
    });
  });

  group('Der quranische Text wird nicht abgetippt', () {
    test('die drei Suren kommen zeichengenau aus kSuras', () {
      // Der Sinn der Übung: Es gibt genau eine Fassung im Repository. Wäre
      // der Text hier abgeschrieben, würde dieser Test ihn beim ersten
      // Zeichen Unterschied auffliegen lassen.
      for (final (String id, int nummer) in <(String, int)>[
        ('sura-ikhlas', 112),
        ('sura-falaq', 113),
        ('sura-nas', 114),
      ]) {
        final Dhikr d = kAzkar.firstWhere((Dhikr d) => d.id == id);
        final QuranSura sura =
            kSuras.firstWhere((QuranSura s) => s.number == nummer);
        expect(d.arabic,
            sura.verses.map((QuranVerse v) => v.arabic).join(' '),
            reason: id);
      }
    });

    test('Āyat al-Kursī trägt ihre Quelle', () {
      final Dhikr d = kAzkar.firstWhere((Dhikr d) => d.id == 'ayat-al-kursi');
      expect(d.source, 'Quran 2:255');
      expect(d.arabic, startsWith('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ'));
      expect(d.arabic, endsWith('الْعَظِيمُ'));
    });
  });

  group('Die Stufen bauen aufeinander auf', () {
    test('Leicht ist eine Teilmenge von Voll, Voll von Vollständig', () {
      for (final AzkarTime t in AzkarTime.values) {
        final Set<String> leicht = <String>{
          for (final Dhikr d
              in azkarFor(time: t, level: AzkarLevel.leicht))
            d.id,
        };
        final Set<String> voll = <String>{
          for (final Dhikr d in azkarFor(time: t, level: AzkarLevel.voll))
            d.id,
        };
        final Set<String> alles = <String>{
          for (final Dhikr d
              in azkarFor(time: t, level: AzkarLevel.vollstaendig))
            d.id,
        };
        expect(voll.containsAll(leicht), isTrue, reason: t.id);
        expect(alles.containsAll(voll), isTrue, reason: t.id);
        expect(voll.length, greaterThan(leicht.length), reason: t.id);
        expect(alles.length, greaterThan(voll.length), reason: t.id);
      }
    });

    test('Leicht sind fünf Azkar, morgens wie abends', () {
      for (final AzkarTime t in AzkarTime.values) {
        expect(azkarFor(time: t, level: AzkarLevel.leicht), hasLength(5),
            reason: t.id);
      }
    });

    test('„Mehr, wenn du magst" ist genau der Rest', () {
      for (final AzkarTime t in AzkarTime.values) {
        for (final AzkarLevel l in AzkarLevel.values) {
          final int drin = azkarFor(time: t, level: l).length;
          final int drueber = azkarDarueberHinaus(time: t, level: l).length;
          final int gesamt =
              kAzkar.where((Dhikr d) => d.giltFuer(t)).length;
          expect(drin + drueber, gesamt, reason: '${t.id}/${l.id}');
        }
      }
      // Auf der höchsten Stufe bleibt nichts übrig.
      expect(
        azkarDarueberHinaus(
            time: AzkarTime.morgens, level: AzkarLevel.vollstaendig),
        isEmpty,
      );
    });
  });

  group('Morgen und Abend', () {
    test('beide Hälften haben Inhalt', () {
      for (final AzkarTime t in AzkarTime.values) {
        expect(azkarFor(time: t, level: AzkarLevel.vollstaendig).length,
            greaterThanOrEqualTo(12), reason: t.id);
      }
    });

    test('die Begrüßungsformel gibt es in beiden Fassungen', () {
      // „aṣbaḥnā" am Morgen, „amsainā" am Abend — dieselbe Bittformel mit
      // dem Wort, das zur Tageszeit passt.
      final Dhikr morgens =
          kAzkar.firstWhere((Dhikr d) => d.id == 'asbahna-morgens');
      final Dhikr abends =
          kAzkar.firstWhere((Dhikr d) => d.id == 'amsayna-abends');
      expect(morgens.times, <AzkarTime>{AzkarTime.morgens});
      expect(abends.times, <AzkarTime>{AzkarTime.abends});
      expect(morgens.arabic, isNot(abends.arabic));
    });

    test('ein Dhikr mit hundert Wiederholungen ist dabei', () {
      expect(kAzkar.any((Dhikr d) => d.count == 100), isTrue);
    });
  });
}
