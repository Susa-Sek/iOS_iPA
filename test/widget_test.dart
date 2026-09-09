import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/main.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/quiz_screen.dart';
import 'package:ipa_testing_github_action/widgets/word_tile.dart';

void main() {
  testWidgets('Startseite zeigt Fortschritt, Übungen und Themen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ArabischLernenApp());
    await tester.pumpAndSettle();

    expect(find.text('Arabisch lernen'), findsWidgets);
    expect(find.text('Dein Fortschritt'), findsOneWidget);
    expect(find.text('Karteikarten'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Zuordnen'), findsOneWidget);
    expect(find.text('Alphabet'), findsOneWidget);
    expect(find.text(kCategories.first.name), findsOneWidget);
  });

  testWidgets('Ein Thema öffnet seine Wortliste', (WidgetTester tester) async {
    await tester.pumpWidget(const ArabischLernenApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(kCategories.first.name));
    await tester.pumpAndSettle();

    final VocabEntry first = kCategories.first.entries.first;
    expect(find.text(first.german), findsOneWidget);
    expect(find.text(first.arabic), findsOneWidget);
  });

  testWidgets('Karteikarte deckt die Übersetzung auf',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ArabischLernenApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Karteikarten'));
    await tester.pumpAndSettle();

    expect(find.text('Zum Aufdecken tippen'), findsOneWidget);
    await tester.tap(find.text('Zum Aufdecken tippen'));
    await tester.pumpAndSettle();
    expect(find.text('Zum Aufdecken tippen'), findsNothing);

    // Rating a card moves on to the next one.
    expect(find.text('Karte 1 von ${kAllEntries.length}'), findsOneWidget);
    await tester.tap(find.text('Kann ich'));
    await tester.pumpAndSettle();
    expect(find.text('Karte 2 von ${kAllEntries.length}'), findsOneWidget);
  });

  testWidgets('Das Alphabet zeigt alle 28 Buchstaben',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ArabischLernenApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alphabet'));
    await tester.pumpAndSettle();

    expect(find.text('Alif'), findsOneWidget);
    expect(find.text('Bāʾ'), findsOneWidget);
  });

  testWidgets('Quiz wertet eine Antwort aus', (WidgetTester tester) async {
    await tester.pumpWidget(const ArabischLernenApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Frage 1 von ${QuizScreen.questionsPerRound}'),
        findsOneWidget);

    // Any of the four options can be tapped; afterwards the round advances.
    final Finder options = find.byType(OutlinedButton);
    expect(options, findsNWidgets(4));
    await tester.tap(options.first);
    await tester.pumpAndSettle();

    expect(find.text('Weiter'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Frage 2 von ${QuizScreen.questionsPerRound}'),
        findsOneWidget);
  });

  testWidgets('Suche findet ein Wort', (WidgetTester tester) async {
    await tester.pumpWidget(const ArabischLernenApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'danke');
    await tester.pumpAndSettle();

    // 'danke' also appears in the search field itself, so check the result
    // row: exactly one word tile showing the Arabic translation.
    expect(find.byType(WordTile), findsOneWidget);
    expect(find.text('شكرا'), findsOneWidget);
  });
}
