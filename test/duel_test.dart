import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/duel.dart';
import 'package:ipa_testing_github_action/state/quiz_builder.dart';

/// Ein Themenverzeichnis, wie es die App beim Einlesen mitgibt.
String? themaZu(int summe) {
  for (final VocabCategory c in kKnowledgeCategories) {
    if (stableHash(c.id) & 0xFFFF == summe) return c.id;
  }
  return null;
}

void main() {
  final VocabCategory thema = kKnowledgeCategories.first;

  Duel neues({int seed = 0}) => newDuel(
        topicId: thema.id,
        pool: thema.entries,
        random: Random(seed),
      );

  group('Der Code', () {
    test('kommt hin und zurück', () {
      final Duel duell = neues();
      final String code = encodeDuel(duell);
      final Duel? zurueck = decodeDuel(code, topicByHash: themaZu);

      expect(zurueck, isNotNull);
      expect(zurueck, duell);
      expect(zurueck!.seed, duell.seed);
      expect(zurueck.count, duell.count);
      expect(zurueck.fingerprint, duell.fingerprint);
      expect(zurueck.topicId, thema.id);
    });

    test('ist kurz genug zum Verschicken', () {
      final String code = encodeDuel(neues());
      expect(code.length, lessThanOrEqualTo(24), reason: code);
      expect(code, startsWith('TK-'));
    });

    test('enthält keine verwechselbaren Zeichen', () {
      // Ohne I, L, O und U: 1 und 0 beim Abtippen, V beim U.
      for (int seed = 0; seed < 200; seed++) {
        final String code = encodeDuel(neues(seed: seed));
        expect(RegExp(r'[ILOU]').hasMatch(code), isFalse, reason: code);
      }
    });

    test('wird aus einer ganzen Nachricht herausgelesen', () {
      final Duel duell = neues();
      final String code = encodeDuel(duell);
      final String nachricht =
          'Hey! Schaffst du das? 🙂\n$code\nViel Glück 👍';
      expect(decodeDuel(nachricht, topicByHash: themaZu), duell);
    });

    test('ein verdrehtes Zeichen gibt keine andere Runde, sondern keine', () {
      final String code = encodeDuel(neues());
      // Ein Zeichen außerhalb des Alphabets.
      final String kaputt = code.replaceFirst(RegExp(r'[0-9A-Z]'), 'I');
      expect(decodeDuel(kaputt, topicByHash: themaZu), isNull);
    });

    test('Unsinn ergibt nichts', () {
      for (final String text in <String>[
        '',
        'Hallo',
        'TK-',
        'TK-ABC',
        'TK-0000-0000-0000-0000',
        'TKE-3F9A2K7M',
      ]) {
        expect(decodeDuel(text, topicByHash: themaZu), isNull, reason: text);
      }
    });

    test('ein unbekanntes Thema wird abgelehnt', () {
      // Ein Code aus einer App mit anderem Bestand: Lieber nichts als die
      // falsche Runde.
      final String code = encodeDuel(neues());
      expect(decodeDuel(code, topicByHash: (int _) => null), isNull);
    });
  });

  group('Der Fingerabdruck', () {
    test('ist für denselben Bestand derselbe', () {
      expect(fingerprintOf(thema.entries), fingerprintOf(thema.entries));
    });

    test('überlebt eine andere Reihenfolge', () {
      final List<VocabEntry> anders = thema.entries.reversed.toList();
      expect(fingerprintOf(anders), fingerprintOf(thema.entries));
    });

    test('ändert sich, wenn eine Frage dazukommt', () {
      final List<VocabEntry> mehr = <VocabEntry>[
        ...thema.entries,
        kKnowledgeCategories[1].entries.first,
      ];
      expect(fingerprintOf(mehr), isNot(fingerprintOf(thema.entries)));
    });

    test('unterscheidet zwei Themen', () {
      expect(fingerprintOf(kKnowledgeCategories[0].entries),
          isNot(fingerprintOf(kKnowledgeCategories[1].entries)));
    });

    test('hängt nicht an Dart-Hashes', () {
      // stableHash muss über Läufe hinweg denselben Wert geben — sonst
      // bauen zwei Telefone aus demselben Code verschiedene Runden.
      expect(stableHash('w_geografie'), stableHash('w_geografie'));
      expect(stableHash('w_geografie'), isNot(stableHash('w_geschichte')));
    });
  });

  group('Beide Seiten bekommen dieselbe Runde', () {
    test('dieselben Fragen in derselben Reihenfolge', () {
      final Duel duell = neues();
      // Das zweite Telefon kennt nur den Code.
      final Duel? drueben =
          decodeDuel(encodeDuel(duell), topicByHash: themaZu);
      expect(drueben, isNotNull);

      final List<QuizQuestion> hier =
          buildDuelRound(duel: duell, pool: thema.entries);
      final List<QuizQuestion> dort =
          buildDuelRound(duel: drueben!, pool: thema.entries);

      expect(hier, hasLength(duell.count));
      for (int i = 0; i < hier.length; i++) {
        expect(dort[i].entry.id, hier[i].entry.id, reason: 'Frage $i');
        expect(dort[i].prompt, hier[i].prompt);
        // Auch die Antworten müssen an derselben Stelle stehen: Sonst
        // wäre „die zweite von oben" auf beiden Telefonen etwas anderes.
        expect(dort[i].options, hier[i].options, reason: 'Antworten $i');
        expect(dort[i].answer, hier[i].answer);
      }
    });

    test('auch wenn der Vorrat anders sortiert ankommt', () {
      // Eine gemerkte Karte kann die Reihenfolge im Speicher ändern.
      final Duel duell = neues();
      final List<QuizQuestion> hier =
          buildDuelRound(duel: duell, pool: thema.entries);
      final List<QuizQuestion> dort = buildDuelRound(
        duel: duell,
        pool: thema.entries.reversed.toList(),
      );
      for (int i = 0; i < hier.length; i++) {
        expect(dort[i].entry.id, hier[i].entry.id, reason: 'Frage $i');
        expect(dort[i].options, hier[i].options, reason: 'Antworten $i');
      }
    });

    test('verschiedene Codes geben verschiedene Runden', () {
      final List<String> erste = <String>[];
      for (int seed = 0; seed < 5; seed++) {
        erste.add(buildDuelRound(duel: neues(seed: seed), pool: thema.entries)
            .map((QuizQuestion q) => q.entry.id)
            .join('|'));
      }
      expect(erste.toSet().length, greaterThan(1));
    });

    test('funktioniert auch mit Vokabeln', () {
      final VocabCategory wort = kCategories.first;
      final Duel duell = newDuel(
        topicId: wort.id,
        pool: wort.entries,
        random: Random(7),
      );
      final List<QuizQuestion> runde =
          buildDuelRound(duel: duell, pool: wort.entries);
      expect(runde, hasLength(duell.count));
      for (final QuizQuestion q in runde) {
        expect(q.options, hasLength(4));
        expect(q.options, contains(q.answer));
      }
    });

    test('ein winziges Thema bricht nicht', () {
      final List<VocabEntry> klein = thema.entries.take(3).toList();
      final Duel duell =
          newDuel(topicId: thema.id, pool: klein, random: Random(1));
      expect(duell.count, 3);
      expect(buildDuelRound(duel: duell, pool: klein), hasLength(3));
    });
  });

  group('Der Ergebnis-Code', () {
    test('kommt hin und zurück', () {
      final Duel duell = neues();
      const DuelResult ergebnis =
          DuelResult(duelId: 0, correct: 8, total: 10);
      final DuelResult mit = DuelResult(
        duelId: duell.id,
        correct: ergebnis.correct,
        total: ergebnis.total,
      );

      final DuelResult? zurueck = decodeResult(encodeResult(mit));
      expect(zurueck, isNotNull);
      expect(zurueck!.duelId, duell.id);
      expect(zurueck.correct, 8);
      expect(zurueck.total, 10);
    });

    test('ordnet sich der richtigen Runde zu', () {
      final Duel eins = neues(seed: 1);
      final Duel zwei = neues(seed: 2);
      expect(eins.id, isNot(zwei.id));

      final DuelResult? gelesen = decodeResult(encodeResult(
          DuelResult(duelId: eins.id, correct: 5, total: 10)));
      expect(gelesen!.duelId, eins.id);
      expect(gelesen.duelId, isNot(zwei.id));
    });

    test('wird aus einer ganzen Nachricht herausgelesen', () {
      final String code = encodeResult(
          DuelResult(duelId: neues().id, correct: 9, total: 10));
      expect(decodeResult('Puh, knapp! 9 von 10 — $code'), isNotNull);
    });

    test('Unsinn ergibt nichts', () {
      for (final String text in <String>[
        '',
        'TKE-',
        'TKE-IIIIIIII',
        'TK-4G7Q-M2XP-RB91-KTZ4',
      ]) {
        expect(decodeResult(text), isNull, reason: text);
      }
    });

    test('mehr richtig als gestellt wird abgelehnt', () {
      // Kein Betrugsschutz — nur die Weigerung, Unsinn anzuzeigen.
      final String code =
          encodeResult(const DuelResult(duelId: 1, correct: 12, total: 10));
      expect(decodeResult(code), isNull);
    });
  });
}
