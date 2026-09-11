import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/state/daily_quests.dart';

List<Quest> aufgaben(
  DateTime tag, {
  int ziel = 10,
  bool arabisch = true,
  bool wissen = true,
}) =>
    buildQuests(
      day: tag,
      dailyGoal: ziel,
      hatArabisch: arabisch,
      hatWissen: wissen,
    );

void main() {
  group('Tagesaufgaben', () {
    test('drei Stück, jede Art höchstens einmal', () {
      for (int i = 0; i < 120; i++) {
        final DateTime tag = DateTime(2026, 1, 1).add(Duration(days: i));
        final List<Quest> heute = aufgaben(tag);
        expect(heute, hasLength(kQuestsPerDay), reason: '$tag');
        expect(heute.map((Quest q) => q.kind).toSet(), hasLength(3),
            reason: '$tag: ${heute.map((Quest q) => q.kind.id)}');
      }
    });

    test('aus dem Datum abgeleitet, nicht gewürfelt', () {
      // Der Kern: Wer die App schließt und wieder öffnet, findet dieselben
      // Aufgaben vor — sonst wäre jeder Fortschritt daran wertlos.
      final DateTime tag = DateTime(2026, 3, 14, 9, 30);
      final List<String> a =
          aufgaben(tag).map((Quest q) => q.kind.id).toList();
      final List<String> b =
          aufgaben(tag).map((Quest q) => q.kind.id).toList();
      expect(a, b);
    });

    test('die Uhrzeit ändert nichts, der Tag schon', () {
      final List<String> morgens = aufgaben(DateTime(2026, 3, 14, 6))
          .map((Quest q) => q.kind.id)
          .toList();
      final List<String> abends = aufgaben(DateTime(2026, 3, 14, 23, 59))
          .map((Quest q) => q.kind.id)
          .toList();
      expect(morgens, abends);
    });

    test('genau eine zählende Aufgabe, wenn es genug Übungen gibt', () {
      for (int i = 0; i < 60; i++) {
        final DateTime tag = DateTime(2026, 6, 1).add(Duration(days: i));
        final int zaehlend =
            aufgaben(tag).where((Quest q) => q.kind.zaehlt).length;
        expect(zaehlend, 1, reason: '$tag');
      }
    });

    test('ohne Wissen keine Lektion und kein Feed', () {
      for (int i = 0; i < 60; i++) {
        final DateTime tag = DateTime(2026, 2, 1).add(Duration(days: i));
        final Set<QuestKind> arten =
            aufgaben(tag, wissen: false).map((Quest q) => q.kind).toSet();
        expect(arten, isNot(contains(QuestKind.lektion)), reason: '$tag');
        expect(arten, isNot(contains(QuestKind.feed)), reason: '$tag');
      }
    });

    test('ohne Arabisch keine Kurzrunde', () {
      for (int i = 0; i < 60; i++) {
        final DateTime tag = DateTime(2026, 2, 1).add(Duration(days: i));
        final Set<QuestKind> arten =
            aufgaben(tag, arabisch: false).map((Quest q) => q.kind).toSet();
        expect(arten, isNot(contains(QuestKind.kurzrunde)), reason: '$tag');
      }
    });

    test('ganz ohne Inhalt bleiben drei machbare Aufgaben übrig', () {
      final List<Quest> heute =
          aufgaben(DateTime(2026, 4, 4), arabisch: false, wissen: false);
      expect(heute, hasLength(3));
      expect(heute.map((Quest q) => q.kind).toSet(), <QuestKind>{
        QuestKind.antworten,
        QuestKind.richtige,
        QuestKind.fehlerfrei,
      });
    });

    test('über einen Monat kommt jede Art vor', () {
      // Sonst wäre die Abwechslung nur behauptet.
      final Set<QuestKind> gesehen = <QuestKind>{};
      for (int i = 0; i < 31; i++) {
        gesehen.addAll(aufgaben(DateTime(2026, 7, 1).add(Duration(days: i)))
            .map((Quest q) => q.kind));
      }
      expect(gesehen, QuestKind.values.toSet());
    });

    test('nicht jeden Tag dieselben drei', () {
      final Set<String> folgen = <String>{};
      for (int i = 0; i < 14; i++) {
        folgen.add(aufgaben(DateTime(2026, 8, 1).add(Duration(days: i)))
            .map((Quest q) => q.kind.id)
            .join('+'));
      }
      expect(folgen.length, greaterThan(3),
          reason: 'zu wenig Abwechslung: $folgen');
    });

    test('die Zahlen hängen am Tagesziel', () {
      final List<Quest> klein = aufgaben(DateTime(2026, 9, 9), ziel: 5);
      final List<Quest> gross = aufgaben(DateTime(2026, 9, 9), ziel: 40);
      for (int i = 0; i < klein.length; i++) {
        expect(klein[i].kind, gross[i].kind);
        if (!klein[i].kind.zaehlt) continue;
        expect(gross[i].target, greaterThan(klein[i].target));
      }
    });

    test('jede Aufgabe hat einen Text mit ihrer Zahl und Punkte', () {
      for (final Quest q in aufgaben(DateTime(2026, 5, 5))) {
        expect(q.label.trim(), isNotEmpty);
        expect(q.xp, greaterThan(0));
        expect(q.target, greaterThan(0));
        if (q.kind.zaehlt) {
          expect(q.label, contains('${q.target}'), reason: q.label);
        }
      }
    });

    test('erledigt ist erledigt, auch über das Ziel hinaus', () {
      final Quest q = aufgaben(DateTime(2026, 5, 5)).first;
      expect(q.isDone(q.target - 1), isFalse);
      expect(q.isDone(q.target), isTrue);
      expect(q.isDone(q.target + 5), isTrue);
      expect(q.ratio(q.target * 2), 1);
      expect(q.ratio(0), 0);
    });

    test('ein Tagesziel außerhalb des Erlaubten bricht nichts', () {
      for (final int ziel in <int>[0, -3, 9999]) {
        final List<Quest> heute = aufgaben(DateTime(2026, 5, 5), ziel: ziel);
        expect(heute, hasLength(3));
        for (final Quest q in heute) {
          expect(q.target, greaterThan(0), reason: 'Ziel $ziel');
        }
      }
    });
  });
}
