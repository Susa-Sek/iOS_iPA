import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/reminder_texts.dart';

void main() {
  const VocabEntry gesundheit = VocabEntry('Gesundheit', 'عافية', "'āfiya");
  const VocabEntry wissen =
      VocabEntry.fact('Höchster Berg Europas', 'Elbrus');

  ReminderText text(
    DateTime day, {
    ReminderSlot slot = ReminderSlot.abends,
    ReminderFacts facts = const ReminderFacts(),
  }) =>
      buildReminderText(day: day, slot: slot, facts: facts);

  group('Derselbe Tag, derselbe Text', () {
    test('zweimal gefragt kommt dasselbe heraus', () {
      final ReminderText a = text(DateTime(2026, 5, 1));
      final ReminderText b = text(DateTime(2026, 5, 1, 23, 59));
      expect(a.title, b.title);
      expect(a.body, b.body);
    });

    test('die drei Lern-Anstöße eines Tages sind nicht derselbe Satz', () {
      final DateTime tag = DateTime(2026, 5, 1);
      final Set<String> texte = <String>{
        for (final ReminderSlot slot in ReminderSlot.values)
          if (!slot.istAzkar) text(tag, slot: slot).body,
      };
      expect(texte.length, 3);
    });
  });

  group('Der Text nutzt sich nicht ab', () {
    test('vierzehn Tage bringen viele verschiedene Sätze', () {
      // Genau daran ist die alte Erinnerung gescheitert: ab morgen stand
      // vierzehn Tage lang wörtlich derselbe Satz.
      final Set<String> texte = <String>{
        for (int tag = 0; tag < 14; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag))).body,
      };
      expect(texte.length, greaterThanOrEqualTo(5));
    });

    test('nie dreimal derselbe Satz hintereinander', () {
      final List<String> texte = <String>[
        for (int tag = 0; tag < 30; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag))).body,
      ];
      for (int i = 2; i < texte.length; i++) {
        expect(texte[i] == texte[i - 1] && texte[i] == texte[i - 2], isFalse,
            reason: 'dreimal „${texte[i]}" ab Tag ${i - 2}');
      }
    });
  });

  group('Keine Zahl, die nicht stimmt', () {
    test('ohne Lernstand steht keine Zahl in der Meldung', () {
      for (int tag = 0; tag < 30; tag++) {
        for (final ReminderSlot slot in ReminderSlot.values) {
          final ReminderText t =
              text(DateTime(2026, 5, 1).add(Duration(days: tag)), slot: slot);
          expect(RegExp(r'\d').hasMatch('${t.title} ${t.body}'), isFalse,
              reason: t.toString());
        }
      }
    });

    test('ohne Serie keine Serien-Drohung', () {
      for (int tag = 0; tag < 30; tag++) {
        final ReminderText t = text(
          DateTime(2026, 5, 1).add(Duration(days: tag)),
          facts: const ReminderFacts(streak: 2, goalRemaining: 8),
        );
        expect(t.title, isNot(contains('Serie')));
        expect(t.title, isNot(contains('Tag ')));
      }
    });

    test('die fälligen Wiederholungen werden nur genannt, wenn es welche gibt',
        () {
      const ReminderFacts keine = ReminderFacts(blockOpen: 4);
      for (int tag = 0; tag < 30; tag++) {
        final ReminderText t = text(
          DateTime(2026, 5, 1).add(Duration(days: tag)),
          slot: ReminderSlot.mittags,
          facts: keine,
        );
        expect(t.body, isNot(contains('Wiederholung')));
      }
    });
  });

  group('Die Serie am Abend', () {
    const ReminderFacts inGefahr =
        ReminderFacts(streak: 12, goalRemaining: 8);

    test('ab drei Tagen und offenem Ziel steht sie abends im Titel', () {
      for (int tag = 0; tag < 14; tag++) {
        final ReminderText t = text(
          DateTime(2026, 5, 1).add(Duration(days: tag)),
          facts: inGefahr,
        );
        expect('${t.title} ${t.body}', contains('12'));
      }
    });

    test('morgens bleibt sie außen vor', () {
      // Um acht ist noch nichts in Gefahr; Druck gehört an den Abend.
      final Set<String> titel = <String>{
        for (int tag = 0; tag < 14; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag)),
                  slot: ReminderSlot.morgens, facts: inGefahr)
              .title,
      };
      expect(titel.any((String t) => t.contains('Tag 12')), isFalse);
    });

    test('mit erreichtem Ziel ist nichts in Gefahr', () {
      final ReminderText t = text(
        DateTime(2026, 5, 1),
        facts: const ReminderFacts(streak: 12),
      );
      expect(t.title, isNot(contains('Tag 12')));
    });

    test('ein Jokertag wird ehrlich erwähnt', () {
      final Set<String> texte = <String>{
        for (int tag = 0; tag < 30; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag)),
                  facts: const ReminderFacts(
                      streak: 5, goalRemaining: 3, freezes: 2))
              .body,
      };
      expect(texte.any((String t) => t.contains('Jokertag')), isTrue);
    });
  });

  group('Ein Wort zum Mitnehmen', () {
    test('morgens steht ein Wort aus dem Arbeitsvorrat drin', () {
      final Set<String> texte = <String>{
        for (int tag = 0; tag < 20; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag)),
                  slot: ReminderSlot.morgens,
                  facts: const ReminderFacts(
                      woerter: <VocabEntry>[gesundheit]))
              .body,
      };
      expect(texte.any((String t) => t.contains('Gesundheit')), isTrue);
      for (final String t in texte) {
        if (t.contains('Gesundheit')) expect(t, contains("'āfiya"));
      }
    });

    test('eine Wissenskarte zeigt ihre Antwort statt einer Lautschrift', () {
      final Set<String> texte = <String>{
        for (int tag = 0; tag < 20; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag)),
                  slot: ReminderSlot.morgens,
                  facts: const ReminderFacts(woerter: <VocabEntry>[wissen]))
              .body,
      };
      final String treffer =
          texte.firstWhere((String t) => t.contains('Elbrus'));
      expect(treffer, contains('Höchster Berg Europas'));
    });

    test('ohne Wörter kommt trotzdem ein Text', () {
      final ReminderText t =
          text(DateTime(2026, 5, 1), slot: ReminderSlot.morgens);
      expect(t.title, isNotEmpty);
      expect(t.body, isNotEmpty);
    });
  });

  group('Die Azkar-Anstöße', () {
    test('rufen zu den Azkar, nicht zum Lernen', () {
      // Ein Satz über fällige Vokabeln wäre hier schlicht falsch.
      const ReminderFacts voll = ReminderFacts(
        streak: 12,
        goalRemaining: 8,
        blockOpen: 6,
        repetitionsDue: 40,
        woerter: <VocabEntry>[gesundheit],
      );
      for (final ReminderSlot slot in <ReminderSlot>[
        ReminderSlot.azkarMorgens,
        ReminderSlot.azkarAbends,
      ]) {
        for (int tag = 0; tag < 20; tag++) {
          final ReminderText t = text(
              DateTime(2026, 5, 1).add(Duration(days: tag)),
              slot: slot,
              facts: voll);
          expect(t.title, contains('Azkar'));
          expect('${t.title} ${t.body}', isNot(contains('Wort')));
          expect('${t.title} ${t.body}', isNot(contains('Block')));
          expect('${t.title} ${t.body}', isNot(contains('Gesundheit')));
          expect('${t.title} ${t.body}', isNot(contains('12')),
              reason: 'die Lernserie gehört nicht hierher');
        }
      }
    });

    test('Morgen und Abend sind auseinanderzuhalten', () {
      final DateTime tag = DateTime(2026, 5, 1);
      expect(text(tag, slot: ReminderSlot.azkarMorgens).title,
          contains('Morgen-Azkar'));
      expect(text(tag, slot: ReminderSlot.azkarAbends).title,
          contains('Abend-Azkar'));
    });

    test('die eigene Serie erscheint erst ab drei Tagen', () {
      final Set<String> ohne = <String>{
        for (int tag = 0; tag < 20; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag)),
                  slot: ReminderSlot.azkarMorgens,
                  facts: const ReminderFacts(azkarStreakMorgens: 2))
              .title,
      };
      expect(ohne.any((String t) => t.contains('Tag')), isFalse);

      final Set<String> mit = <String>{
        for (int tag = 0; tag < 20; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag)),
                  slot: ReminderSlot.azkarMorgens,
                  facts: const ReminderFacts(azkarStreakMorgens: 12))
              .title,
      };
      expect(mit.any((String t) => t.contains('Tag 12')), isTrue);
    });

    test('die Azkar-Serien bleiben getrennt', () {
      const ReminderFacts facts =
          ReminderFacts(azkarStreakMorgens: 9, azkarStreakAbends: 4);
      final Set<String> morgens = <String>{
        for (int tag = 0; tag < 20; tag++)
          text(DateTime(2026, 5, 1).add(Duration(days: tag)),
                  slot: ReminderSlot.azkarMorgens, facts: facts)
              .title,
      };
      expect(morgens.any((String t) => t.contains('Tag 9')), isTrue);
      expect(morgens.any((String t) => t.contains('Tag 4')), isFalse);
    });
  });

  group('Passt in eine Benachrichtigung', () {
    test('Titel und Text bleiben kurz', () {
      const ReminderFacts voll = ReminderFacts(
        streak: 123,
        freezes: 3,
        blockNumber: 81,
        blockOpen: 30,
        repetitionsDue: 999,
        goalRemaining: 5,
        woerter: <VocabEntry>[gesundheit, wissen],
      );
      for (int tag = 0; tag < 60; tag++) {
        for (final ReminderSlot slot in ReminderSlot.values) {
          final ReminderText t = text(
              DateTime(2026, 5, 1).add(Duration(days: tag)),
              slot: slot,
              facts: voll);
          expect(t.title.length, lessThanOrEqualTo(40), reason: t.title);
          expect(t.body.length, lessThanOrEqualTo(120), reason: t.body);
        }
      }
    });
  });
}
