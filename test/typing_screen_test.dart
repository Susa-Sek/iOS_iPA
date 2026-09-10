import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/typing_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

import 'helpers.dart';

const VocabEntry _mauerfall = VocabEntry.question(
  'In welchem Jahr fiel die Berliner Mauer?',
  '1989',
  distractors: <String>['1987', '1990', '1991'],
  explanation: 'Am 9. November 1989.',
);

const VocabEntry _leber = VocabEntry.question(
  'Welches Organ bildet die Galle?',
  'Die Leber',
  distractors: <String>['Die Niere', 'Die Milz', 'Der Magen'],
  explanation: 'Die Nieren filtern das Blut.',
);

const List<VocabEntry> _karten = <VocabEntry>[_mauerfall, _leber];

Future<void> _tippen(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.text('Prüfen'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Tippen', () {
    testWidgets('zeigt die Frage und ein Eingabefeld',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapScreen(
          const TypingScreen(entries: _karten, title: 'Test')));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Prüfen'), findsOneWidget);
      expect(find.text('Wort 1 von 2'), findsOneWidget);
    });

    testWidgets('eine richtige Eingabe zählt', (WidgetTester tester) async {
      final LearningState state = LearningState();
      await state.load();
      await tester.pumpWidget(wrapScreen(
          const TypingScreen(entries: _karten, title: 'Test'),
          state: state));
      await tester.pumpAndSettle();

      // Die Reihenfolge ist zufällig — getippt wird, was gerade dran ist.
      final VocabEntry dran = _karten.firstWhere((VocabEntry e) =>
          find.text(e.prompt).evaluate().isNotEmpty);
      await _tippen(tester, dran.answer);

      expect(find.text('Richtig.'), findsOneWidget);
      expect(state.correct, 1);
      expect(state.boxOf(dran), greaterThan(0));
    });

    testWidgets('eine falsche Eingabe nennt die richtige Antwort',
        (WidgetTester tester) async {
      final LearningState state = LearningState();
      await state.load();
      await tester.pumpWidget(wrapScreen(
          const TypingScreen(entries: _karten, title: 'Test'),
          state: state));
      await tester.pumpAndSettle();

      final VocabEntry dran = _karten.firstWhere((VocabEntry e) =>
          find.text(e.prompt).evaluate().isNotEmpty);
      await _tippen(tester, 'völlig daneben');

      expect(find.text('Richtig wäre gewesen:'), findsOneWidget);
      expect(find.text(dran.answer), findsOneWidget);
      expect(state.correct, 0);
      expect(state.answered, 1);
    });

    testWidgets('fast richtig zählt und zeigt die Schreibweise',
        (WidgetTester tester) async {
      const List<VocabEntry> eine = <VocabEntry>[_leber];
      final LearningState state = LearningState();
      await state.load();
      await tester.pumpWidget(wrapScreen(
          const TypingScreen(entries: eine, title: 'Test'), state: state));
      await tester.pumpAndSettle();

      await _tippen(tester, 'Lebar');

      expect(find.text('Fast — so wird es geschrieben:'), findsOneWidget);
      expect(find.text('Die Leber'), findsOneWidget);
      expect(state.correct, 1);
    });

    testWidgets('nach der letzten Karte kommt das Ergebnis',
        (WidgetTester tester) async {
      const List<VocabEntry> eine = <VocabEntry>[_mauerfall];
      await tester.pumpWidget(wrapScreen(
          const TypingScreen(entries: eine, title: 'Test')));
      await tester.pumpAndSettle();

      await _tippen(tester, '1989');
      await tester.tap(find.text('Ergebnis ansehen'));
      await tester.pumpAndSettle();

      expect(find.text('1 von 1 getroffen'), findsOneWidget);
      expect(find.text('Neue Runde'), findsOneWidget);
    });

    testWidgets('ohne geeignete Einträge steht ein Hinweis da',
        (WidgetTester tester) async {
      const List<VocabEntry> zuLang = <VocabEntry>[
        VocabEntry.fact('Binnenmarkt',
            'Freier Verkehr von Waren, Personen, Diensten und Kapital'),
      ];
      await tester.pumpWidget(wrapScreen(
          const TypingScreen(entries: zuLang, title: 'Test')));
      await tester.pumpAndSettle();

      expect(find.textContaining('kurz genug tippen'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('Layout', () {
    for (final double scale in <double>[1.0, 1.5]) {
      testWidgets('auf 320 px bei ${(scale * 100).toInt()} Prozent Schrift',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Die längsten Aufgaben, die im Bestand wirklich vorkommen.
        final List<VocabEntry> lang =
            List<VocabEntry>.of(kKnowledgeEntries.where(TypingScreen.isSuitable))
              ..sort((VocabEntry a, VocabEntry b) =>
                  b.prompt.length.compareTo(a.prompt.length));

        await tester.pumpWidget(scale == 1.0
            ? wrapScreen(TypingScreen(entries: lang.take(5).toList(),
                title: 'Wissen'))
            : wrapScreenScaled(TypingScreen(entries: lang.take(5).toList(),
                title: 'Wissen')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'irgendwas');
        // Bei großer Schrift auf einem kleinen Telefon liegt der Knopf unter
        // dem Rand — die Liste scrollt, statt überzulaufen. Auf dem Gerät
        // genügt sonst die Eingabetaste.
        // Bei großer Schrift auf einem kleinen Telefon liegt der Knopf unter
        // dem Rand — die Liste scrollt, statt überzulaufen. Auf dem Gerät
        // genügt sonst die Eingabetaste.
        await tester.dragUntilVisible(
          find.text('Prüfen'),
          find.byType(ListView),
          const Offset(0, -80),
        );
        await tester.tap(find.text('Prüfen'));
        await tester.pumpAndSettle();
      });
    }
  });
}
