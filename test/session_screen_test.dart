import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/session_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

import 'helpers.dart';

/// Ein Vorrat, aus dem nur Karteikarten und Quiz gebaut werden können.
///
/// Antworten über 28 Zeichen scheiden beim Zuordnen aus, beim Tippen
/// ebenfalls, und Wissenskarten haben keine arabischen Buchstaben zum Bauen.
/// Damit steht die Art der Blöcke fest — und der Test prüft, was er prüfen
/// soll: dass die Kette weiterläuft. Dass die Arten wechseln, prüft
/// `session_plan_test.dart` an der reinen Funktion.
List<VocabEntry> get _langeAntworten => kKnowledgeEntries
    .where((VocabEntry e) => e.answer.length > 28)
    .take(30)
    .toList();

/// Spielt genau eine Aufgabe der laufenden Übung.
Future<bool> _einSchritt(WidgetTester tester) async {
  if (find.text('Zum Aufdecken tippen').evaluate().isNotEmpty) {
    await tester.tap(find.text('Zum Aufdecken tippen'));
    await tester.pumpAndSettle();
  }
  if (find.text('Kann ich').evaluate().isNotEmpty) {
    await tester.tap(find.text('Kann ich'));
    await tester.pumpAndSettle();
    return true;
  }
  for (final String knopf in <String>['Weiter', 'Ergebnis ansehen']) {
    if (find.text(knopf).evaluate().isNotEmpty) {
      await tester.tap(find.text(knopf));
      await tester.pumpAndSettle();
      return true;
    }
  }
  if (find.byType(OutlinedButton).evaluate().isNotEmpty) {
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    return true;
  }
  return false;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<LearningState> geladen() async {
    final LearningState state = LearningState();
    await state.load();
    return state;
  }

  group('Kurzrunde', () {
    testWidgets('startet mit einem Block und zeigt den Fortschritt',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          wrapScreen(SessionScreen(pool: _langeAntworten)));
      await tester.pumpAndSettle();

      expect(find.text('Kurzrunde'), findsWidgets);
      // Der Balken gilt für die ganze Runde, nicht für den laufenden Block.
      expect(find.textContaining('1. von 3 Übungen'), findsOneWidget);
    });

    testWidgets('läuft von Anfang bis zur Bilanz durch',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final LearningState state = await geladen();
      await tester.pumpWidget(
          wrapScreen(SessionScreen(pool: _langeAntworten), state: state));
      await tester.pumpAndSettle();

      // Großzügig viele Schritte: Die Runde ist kurz, aber die Zahl der
      // Aufgaben je Art ist verschieden.
      for (int i = 0; i < 60; i++) {
        if (find.text('Runde geschafft').evaluate().isNotEmpty) break;
        if (!await _einSchritt(tester)) break;
      }

      expect(find.text('Runde geschafft'), findsOneWidget);
      expect(find.text('Noch eine Runde'), findsOneWidget);
      expect(find.text('Fertig'), findsOneWidget);
      // Unterwegs wurde wirklich gelernt.
      expect(state.answered, greaterThan(0));
    });

    testWidgets('der Fortschritt zählt die Blöcke, nicht die Aufgaben',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          wrapScreen(SessionScreen(pool: _langeAntworten)));
      await tester.pumpAndSettle();
      expect(find.textContaining('1. von 3 Übungen'), findsOneWidget);

      // Den ersten Block zu Ende spielen — danach steht der zweite an.
      for (int i = 0; i < 20; i++) {
        if (find.textContaining('2. von 3 Übungen').evaluate().isNotEmpty) {
          break;
        }
        if (!await _einSchritt(tester)) break;
      }
      expect(find.textContaining('2. von 3 Übungen'), findsOneWidget);
    });

    testWidgets('ein leerer Vorrat sagt es, statt leer dazustehen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          wrapScreen(const SessionScreen(pool: <VocabEntry>[])));
      await tester.pumpAndSettle();

      expect(find.textContaining('nichts zusammenzustellen'), findsOneWidget);
    });

    testWidgets('keine der Übungen bringt eine eigene Kopfzeile mit',
        (WidgetTester tester) async {
      // Zwei Kopfzeilen übereinander wären der sichtbare Beweis, dass die
      // Einbettung nicht greift.
      await tester.pumpWidget(
          wrapScreen(SessionScreen(pool: _langeAntworten)));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('Layout', () {
    for (final double scale in <double>[1.0, 1.5]) {
      testWidgets('auf 320 px bei ${(scale * 100).toInt()} Prozent Schrift',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final Widget screen = SessionScreen(pool: _langeAntworten);
        await tester.pumpWidget(
            scale == 1.0 ? wrapScreen(screen) : wrapScreenScaled(screen));
        await tester.pumpAndSettle();
      });
    }
  });
}
