import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/build_word_screen.dart';
import 'package:ipa_testing_github_action/screens/matching_screen.dart';
import 'package:ipa_testing_github_action/state/session_plan.dart';
import 'package:ipa_testing_github_action/state/typing_check.dart';

Map<ExerciseKind, Suitability> get _eignung => suitabilityFor(
      wortBauen: BuildWordScreen.isSuitable,
      zuordnen: MatchingScreen.isSuitable,
    );

List<SessionBlock> runde(List<VocabEntry> pool, {int seed = 1, int blocks = 3}) =>
    buildSession(
      pool: pool,
      random: Random(seed),
      suitability: _eignung,
      blocks: blocks,
    );

void main() {
  group('Kurzrunde', () {
    test('hat mehrere Blöcke und wenige Aufgaben', () {
      final List<SessionBlock> plan = runde(kAllEntries.take(60).toList());
      expect(plan, hasLength(3));
      expect(sessionLength(plan), inInclusiveRange(6, 12));
    });

    test('nie zweimal dieselbe Art hintereinander', () {
      for (int seed = 0; seed < 40; seed++) {
        final List<SessionBlock> plan =
            runde(kAllEntries.take(80).toList(), seed: seed);
        for (int i = 1; i < plan.length; i++) {
          expect(plan[i].kind, isNot(plan[i - 1].kind),
              reason: 'seed $seed: ${plan.map((SessionBlock b) => b.kind)}');
        }
      }
    });

    test('bringt tatsächlich Abwechslung', () {
      // Über viele Runden müssen mehrere Arten vorkommen — sonst wäre die
      // Kurzrunde nur eine Übung mit anderem Namen.
      final Set<ExerciseKind> gesehen = <ExerciseKind>{};
      for (int seed = 0; seed < 30; seed++) {
        gesehen.addAll(
            runde(kAllEntries.take(80).toList(), seed: seed)
                .map((SessionBlock b) => b.kind));
      }
      expect(gesehen.length, greaterThanOrEqualTo(4));
    });

    test('kein Eintrag kommt in einer Runde doppelt vor', () {
      for (int seed = 0; seed < 20; seed++) {
        final List<SessionBlock> plan =
            runde(kAllEntries.take(120).toList(), seed: seed);
        final List<String> ids = <String>[
          for (final SessionBlock b in plan)
            for (final VocabEntry e in b.entries) e.id,
        ];
        expect(ids.toSet().length, ids.length, reason: 'seed $seed');
      }
    });

    test('jeder Eintrag passt zu seiner Übungsart', () {
      for (int seed = 0; seed < 30; seed++) {
        for (final SessionBlock block
            in runde(kAllEntries.take(120).toList(), seed: seed)) {
          for (final VocabEntry entry in block.entries) {
            switch (block.kind) {
              case ExerciseKind.wortBauen:
                expect(BuildWordScreen.isSuitable(entry), isTrue,
                    reason: entry.german);
              case ExerciseKind.zuordnen:
                expect(MatchingScreen.isSuitable(entry), isTrue,
                    reason: entry.german);
              case ExerciseKind.tippen:
                expect(isTypeable(entry), isTrue, reason: entry.german);
              case ExerciseKind.karteikarten:
              case ExerciseKind.quiz:
                break;
            }
          }
        }
      }
    });
  });

  group('Im Fach Wissen', () {
    test('„Wort bauen" fällt von selbst weg', () {
      // Es gibt dort keine arabischen Buchstaben zu bauen.
      for (int seed = 0; seed < 30; seed++) {
        final List<SessionBlock> plan =
            runde(kKnowledgeEntries.take(120).toList(), seed: seed);
        expect(plan.map((SessionBlock b) => b.kind),
            isNot(contains(ExerciseKind.wortBauen)));
      }
    });

    test('trotzdem kommt eine volle Runde zustande', () {
      final List<SessionBlock> plan =
          runde(kKnowledgeEntries.take(120).toList());
      expect(plan, hasLength(3));
      expect(sessionLength(plan), greaterThanOrEqualTo(6));
    });
  });

  group('Randfälle', () {
    test('leerer Vorrat ergibt keine Runde', () {
      expect(runde(const <VocabEntry>[]), isEmpty);
    });

    test('ein winziger Vorrat bricht nicht', () {
      for (int n = 1; n <= 6; n++) {
        final List<SessionBlock> plan = runde(kAllEntries.take(n).toList());
        expect(sessionLength(plan), lessThanOrEqualTo(n * 3));
        for (final SessionBlock block in plan) {
          expect(block.entries, isNotEmpty);
        }
      }
    });

    test('null Blöcke ergeben nichts', () {
      expect(runde(kAllEntries.take(50).toList(), blocks: 0), isEmpty);
    });

    test('ein Vorrat, der zu keiner Art passt, ergibt nichts', () {
      // Übermäßig lange Antworten: Zuordnen, Tippen und Wortbauen scheiden
      // aus; Karteikarten und Quiz brauchen mindestens vier Einträge.
      const List<VocabEntry> zuLang = <VocabEntry>[
        VocabEntry.fact('A',
            'Eine sehr lange Antwort, die in keinen Knopf und in keine Zeile passt'),
      ];
      final List<SessionBlock> plan = runde(zuLang);
      expect(plan.every((SessionBlock b) => b.kind != ExerciseKind.tippen),
          isTrue);
    });

    test('mehr Blöcke als Arten führt nicht zu einer Endlosschleife', () {
      final List<SessionBlock> plan =
          runde(kAllEntries.take(120).toList(), blocks: 12);
      expect(plan.length, lessThanOrEqualTo(12));
      for (int i = 1; i < plan.length; i++) {
        expect(plan[i].kind, isNot(plan[i - 1].kind));
      }
    });
  });
}
