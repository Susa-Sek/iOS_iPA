import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/knowledge/lessons.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';

void main() {
  group('Lektionen', () {
    test('zwei je Thema', () {
      expect(kLessons, hasLength(kKnowledgeCategories.length * 2));
      expect(kLessons, hasLength(42));
    });

    test('jede Lektion hat Lesestoff und Prüfung', () {
      // Das ist die Form, auf der alles steht: erst lesen, dann geprüft
      // werden. Fehlt eine der beiden Hälften, ist es keine Lektion mehr,
      // sondern wieder eine Kartei oder ein Test.
      for (final KnowledgeLesson lesson in kLessons) {
        expect(lesson.reading.length, greaterThanOrEqualTo(2),
            reason: '${lesson.id}: zu wenig Lesestoff');
        expect(lesson.checks.length, greaterThanOrEqualTo(2),
            reason: '${lesson.id}: zu wenig Fragen');
      }
    });

    test('eine Lektion bleibt in fünf Minuten machbar', () {
      for (final KnowledgeLesson lesson in kLessons) {
        expect(lesson.length, inInclusiveRange(4, 9), reason: lesson.id);
      }
    });

    test('jede Lektion hat Titel, Einstieg und Fazit', () {
      for (final KnowledgeLesson lesson in kLessons) {
        // „Teil 1" ist der Notnagel für eine Lektion ohne Text — er darf im
        // ausgelieferten Bestand nicht vorkommen.
        expect(lesson.title, isNot(startsWith('Teil ')), reason: lesson.id);
        expect(lesson.title.trim(), isNotEmpty, reason: lesson.id);
        expect(lesson.intro.trim(), isNotEmpty, reason: lesson.id);
        expect(lesson.takeaway.length, inInclusiveRange(2, 3),
            reason: lesson.id);
        for (final String satz in lesson.takeaway) {
          expect(satz.trim(), isNotEmpty, reason: lesson.id);
          expect(satz, endsWith('.'), reason: '${lesson.id}: „$satz"');
        }
      }
    });

    test('Titel und Einstieg bleiben kurz genug für ein Telefon', () {
      for (final KnowledgeLesson lesson in kLessons) {
        expect(lesson.title.length, lessThanOrEqualTo(44),
            reason: '${lesson.id}: „${lesson.title}"');
        expect(lesson.intro.length, lessThanOrEqualTo(170), reason: lesson.id);
      }
    });

    test('jede id kommt genau einmal vor', () {
      final Set<String> ids = <String>{};
      for (final KnowledgeLesson lesson in kLessons) {
        expect(ids.add(lesson.id), isTrue, reason: 'doppelt: ${lesson.id}');
      }
    });

    test('jede Wissenskarte steckt in genau einer Lektion', () {
      // Sonst gäbe es Inhalt, den man auf dem gedachten Weg nie zu sehen
      // bekommt.
      final List<String> ids = <String>[
        for (final KnowledgeLesson l in kLessons)
          for (final VocabEntry e in l.entries) e.id,
      ];
      expect(ids.length, kKnowledgeEntries.length);
      expect(ids.toSet().length, ids.length);
      expect(ids.toSet(),
          <String>{for (final VocabEntry e in kKnowledgeEntries) e.id});
    });

    test('die Lektionen eines Themas gehören zu diesem Thema', () {
      for (final VocabCategory category in kKnowledgeCategories) {
        final List<KnowledgeLesson> lektionen = lessonsOf(category);
        expect(lektionen, hasLength(2), reason: category.name);
        for (final KnowledgeLesson lesson in lektionen) {
          expect(lesson.categoryId, category.id);
          expect(lesson.id, startsWith('${category.id}.'));
          for (final VocabEntry entry in lesson.entries) {
            expect(category.entries, contains(entry), reason: lesson.id);
          }
        }
      }
    });

    test('die Reihenfolge des Themas bleibt erhalten', () {
      for (final VocabCategory category in kKnowledgeCategories) {
        final List<VocabEntry> ausLektionen = <VocabEntry>[
          for (final KnowledgeLesson l in lessonsOf(category)) ...l.entries,
        ];
        expect(ausLektionen, category.entries, reason: category.name);
      }
    });

    test('lessonById findet und meldet Unbekanntes', () {
      expect(lessonById('w_geografie.1'), isNotNull);
      expect(lessonById('w_geografie.1')!.categoryId, 'w_geografie');
      expect(lessonById('gibtsnicht'), isNull);
    });

    test('ein zu kleines Thema ergibt keine halbe Lektion', () {
      const VocabCategory winzig = VocabCategory(
        id: 'winzig',
        name: 'Winzig',
        icon: Icons.abc,
        color: Color(0xFF000000),
        softColor: Color(0x24000000),
        script: TextScript.latin,
        entries: <VocabEntry>[VocabEntry.fact('A', 'B')],
      );
      expect(lessonsOf(winzig), isEmpty);
    });
  });
}
