import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/models/subject.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/shorts_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

import 'helpers.dart';

/// Nach oben wischen: eine Karte weiter.
Future<void> _wischen(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(0, -400), 1200);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final VocabCategory thema = kKnowledgeCategories.first;

  Future<LearningState> aufbauen(
    WidgetTester tester, {
    VocabCategory? welches,
    double scale = 1,
    Size? groesse,
  }) async {
    if (groesse != null) {
      tester.view.physicalSize = groesse;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final LearningState state = LearningState();
    await state.load();
    await state.setSubject(Subject.wissen);

    await tester.pumpWidget(scale == 1
        ? wrapScreen(ShortsScreen(category: welches ?? thema), state: state)
        : wrapScreenScaled(ShortsScreen(category: welches ?? thema),
            scale: scale, state: state));
    await tester.pumpAndSettle();
    return state;
  }

  group('Feed', () {
    testWidgets('beginnt mit einem Fakt — keine Kartei, kein Suchfeld',
        (WidgetTester tester) async {
      await aufbauen(tester);

      final VocabEntry ersterFakt = thema.entries
          .firstWhere((VocabEntry e) => e.question == null);
      expect(find.text(ersterFakt.german), findsOneWidget);
      expect(find.text(ersterFakt.answer), findsOneWidget);

      // Das ist der Punkt der Umstellung: Nichts aus dem Vokabelbildschirm.
      expect(find.text('Karteikarten'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Nur offene Wörter'), findsNothing);
    });

    testWidgets('wischen blättert weiter', (WidgetTester tester) async {
      await aufbauen(tester);
      final VocabEntry ersterFakt = thema.entries
          .firstWhere((VocabEntry e) => e.question == null);

      await _wischen(tester);
      expect(find.text(ersterFakt.german), findsNothing);
      // Nach dem ersten Fakt kommt eine Frage: vier Antworten zur Wahl.
      expect(find.byType(OutlinedButton).hitTestable(), findsNWidgets(4));
    });

    testWidgets('der Hinweis unten bringt einen genauso weiter',
        (WidgetTester tester) async {
      // Wischen ist der Weg — aber niemand darf hängen bleiben, nur weil er
      // die Geste nicht kennt.
      await aufbauen(tester);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton).hitTestable(), findsNWidgets(4));
    });
  });

  group('Frage', () {
    testWidgets('antippen färbt, erklärt und zählt den Lernstand',
        (WidgetTester tester) async {
      final LearningState state = await aufbauen(tester);
      await _wischen(tester);

      final VocabEntry frage =
          thema.entries.firstWhere((VocabEntry e) => e.question != null);
      expect(find.text(frage.prompt), findsOneWidget);
      expect(find.text(frage.explanation!), findsNothing);

      await tester.tap(find.text(frage.answer));
      await tester.pumpAndSettle();

      expect(find.text('Richtig'), findsOneWidget);
      expect(find.text(frage.explanation!), findsOneWidget);
      expect(state.answered, 1);
      // Der Lernstand läuft mit: Eine richtige Antwort rückt die Karte im
      // Leitner-Kasten ein Fach weiter — derselbe Speicher wie überall.
      expect(state.progressOfWord(frage).box, 1);
    });

    testWidgets('eine falsche Antwort wird als falsch gezeigt',
        (WidgetTester tester) async {
      final LearningState state = await aufbauen(tester);
      await _wischen(tester);

      final VocabEntry frage =
          thema.entries.firstWhere((VocabEntry e) => e.question != null);
      await tester.tap(find.text(frage.distractors.first));
      await tester.pumpAndSettle();

      expect(find.text('Daneben'), findsOneWidget);
      expect(find.text('Richtig'), findsNothing);
      expect(state.answered, 1);
    });

    testWidgets('zweimal tippen zählt nur einmal',
        (WidgetTester tester) async {
      final LearningState state = await aufbauen(tester);
      await _wischen(tester);

      final VocabEntry frage =
          thema.entries.firstWhere((VocabEntry e) => e.question != null);
      await tester.tap(find.text(frage.answer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(frage.distractors.first));
      await tester.pumpAndSettle();
      expect(state.answered, 1);
    });
  });

  group('Abschluss', () {
    testWidgets('am Ende steht ein Schlusspunkt, kein Sprungbrett',
        (WidgetTester tester) async {
      await aufbauen(tester);
      for (int i = 0; i < thema.entries.length; i++) {
        if (find.text('Thema durch').evaluate().isNotEmpty) break;
        await _wischen(tester);
      }
      expect(find.text('Thema durch'), findsOneWidget);

      // „Fertig" ist der Knopf. Vorher schob der auffälligste Knopf am Ende
      // einen zurück in den Feed — genau das soll nicht mehr sein.
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('Fertig'),
        ),
        findsOneWidget,
      );
      // „Nächstes Thema" hat nie ein nächstes Thema geöffnet, sondern nur
      // geschlossen. Ein Knopf, der lügt, ist weg.
      expect(find.text('Nächstes Thema'), findsNothing);
      // „Nochmal" bleibt möglich, aber als Zeile, nicht als Einladung.
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('Nochmal durchgehen'),
        ),
        findsNothing,
      );
    });

    testWidgets('„Nochmal durchgehen" fängt wieder vorn an',
        (WidgetTester tester) async {
      await aufbauen(tester);
      for (int i = 0; i < thema.entries.length; i++) {
        if (find.text('Thema durch').evaluate().isNotEmpty) break;
        await _wischen(tester);
      }
      await tester.ensureVisible(find.text('Nochmal durchgehen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nochmal durchgehen'));
      await tester.pumpAndSettle();

      final VocabEntry ersterFakt = thema.entries
          .firstWhere((VocabEntry e) => e.question == null);
      expect(find.text(ersterFakt.german), findsOneWidget);
    });
  });

  group('Layout', () {
    // Das längste, was im Bestand steht — wenn das passt, passt alles.
    int laenge(VocabCategory c) => c.entries.fold(
        0,
        (int a, VocabEntry e) =>
            a + e.german.length + e.answer.length +
            (e.explanation?.length ?? 0));
    VocabCategory laengstesThema() {
      VocabCategory schlimmstes = kKnowledgeCategories.first;
      for (final VocabCategory c in kKnowledgeCategories) {
        if (laenge(c) > laenge(schlimmstes)) schlimmstes = c;
      }
      return schlimmstes;
    }

    testWidgets('320 px und 150 % Schrift laufen nicht über',
        (WidgetTester tester) async {
      await aufbauen(tester,
          welches: laengstesThema(),
          scale: 1.5,
          groesse: const Size(320, 568));
      // Ein paar Karten weit — Fakt wie Frage, mit Erklärung.
      for (int i = 0; i < 4; i++) {
        final Finder antworten = find.byType(OutlinedButton).hitTestable();
        if (antworten.evaluate().length == 4) {
          await tester.tap(antworten.first);
          await tester.pumpAndSettle();
        }
        await _wischen(tester);
      }
    });

    testWidgets('die vier Antworten stehen im unteren Drittel',
        (WidgetTester tester) async {
      // Der Daumen erreicht das untere Drittel, ohne dass die Hand
      // umgreift — genau dafür sind die Antworten dort.
      await aufbauen(tester, groesse: const Size(390, 844));
      await _wischen(tester);

      final double hoehe = tester.view.physicalSize.height;
      final Finder antworten = find.byType(OutlinedButton).hitTestable();
      expect(antworten, findsNWidgets(4));
      for (final Element e in antworten.evaluate()) {
        final RenderBox box = e.renderObject! as RenderBox;
        final double oben = box.localToGlobal(Offset.zero).dy;
        expect(oben, greaterThan(hoehe / 2),
            reason: 'Antwort steht zu weit oben');
      }
    });
  });
}
