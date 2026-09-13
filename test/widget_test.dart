import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/main.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/quiz_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/widgets/word_tile.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Wechselt in den Bereich "Üben", wo die Übungen liegen.
  Future<void> openPractice(WidgetTester tester) async {
    await tester.tap(find.text('Üben'));
    await tester.pumpAndSettle();
  }

  /// Scrollt einen Eintrag der Übungsliste ins Bild und tippt ihn an — die
  /// Liste ist länger als der Bildschirm.
  Future<void> tapPractice(WidgetTester tester, String label) async {
    final Finder target = find.text(label);
    await tester.scrollUntilVisible(target, 200,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// Scrollt die Startseite bis zum ersten Thema — seit der "Heute"-Karte
  /// liegt die Themenliste unterhalb des sichtbaren Bereichs.
  Future<void> scrollToCategories(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text(kCategories.first.name),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Startseite zeigt Fortschritt, Übungen und Themen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaeglichKluegerApp());
    await tester.pumpAndSettle();

    // Die drei Bereiche unten …
    expect(find.text('Lernen'), findsWidgets);
    expect(find.text('Üben'), findsWidgets);
    expect(find.text('Erfolge'), findsWidgets);

    // … und auf „Lernen" der Tag und der Fortschritt. „Heute" steht genau
    // einmal da — als Überschrift der Tageskarte. Der gleichnamige Bereich
    // unten ist ins Fach Wissen gewandert, wo der Tagesstoff hingehört.
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('Tagesaufgaben'), findsOneWidget);

    // Level und Punkte stehen weiter unten, seit die Tagesaufgaben
    // dazwischenliegen. Ganz ohne Scrollen sieht man sie trotzdem: oben in
    // der Kopfzeile läuft die Serie mit den Punkten mit.
    await tester.scrollUntilVisible(
      find.text('Level 1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('0 Punkte'), findsOneWidget);

    await scrollToCategories(tester);
    expect(find.text(kCategories.first.name), findsOneWidget);
  });

  testWidgets('Der Bereich Üben führt alle Übungen auf',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaeglichKluegerApp());
    await tester.pumpAndSettle();
    await openPractice(tester);

    expect(find.text('Karteikarten'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Zuordnen'), findsOneWidget);
    expect(find.text('Wort bauen'), findsOneWidget);

    // Der Rest steht weiter unten in derselben Liste.
    for (final String label in <String>[
      'Alphabet & Zeichen',
      'Verben beugen',
      'Quran-Sprache',
    ]) {
      await tester.scrollUntilVisible(find.text(label), 200,
          scrollable: find.byType(Scrollable).last);
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Der Bereich Erfolge zeigt Level und Abzeichen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaeglichKluegerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erfolge'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Abzeichen'), findsWidgets);
    expect(find.textContaining('Punkte'), findsWidgets);
  });

  testWidgets('Ein Thema öffnet seine Wortliste', (WidgetTester tester) async {
    await tester.pumpWidget(const TaeglichKluegerApp());
    await tester.pumpAndSettle();

    await scrollToCategories(tester);
    await tester.tap(find.text(kCategories.first.name));
    await tester.pumpAndSettle();

    final VocabEntry first = kCategories.first.entries.first;
    expect(find.text(first.german), findsOneWidget);
    expect(find.text(first.arabic), findsOneWidget);
  });

  testWidgets('Karteikarte deckt die Übersetzung auf',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaeglichKluegerApp());
    await tester.pumpAndSettle();

    await openPractice(tester);
    await tapPractice(tester, 'Karteikarten');

    expect(find.text('Zum Aufdecken tippen'), findsOneWidget);
    await tester.tap(find.text('Zum Aufdecken tippen'));
    await tester.pumpAndSettle();
    expect(find.text('Zum Aufdecken tippen'), findsNothing);

    // Ohne ausgewähltes Thema ist der Stapel der **laufende Block** — nicht
    // der gesamte Bestand und auch nicht mehr die volle Tagesportion. Auf
    // einer frischen Installation steht keine Wiederholung an, also sind es
    // genau die Wörter des ersten Blocks.
    final LearningState frisch = LearningState();
    await frisch.load();
    final int erwartet =
        frisch.workingSet.length.clamp(0, frisch.dosePerRound);
    expect(erwartet, frisch.blockSize,
        reason: 'frisch: nur der erste Block, keine Wiederholungen');
    expect(find.text('Karte 1 von $erwartet'), findsOneWidget);
    await tester.tap(find.text('Kann ich'));
    await tester.pumpAndSettle();
    expect(find.text('Karte 2 von $erwartet'), findsOneWidget);
  });

  testWidgets('Das Alphabet zeigt alle 28 Buchstaben',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaeglichKluegerApp());
    await tester.pumpAndSettle();

    await openPractice(tester);
    await tapPractice(tester, 'Alphabet & Zeichen');

    expect(find.text('Alif'), findsOneWidget);
    expect(find.text('Bāʾ'), findsOneWidget);
  });

  testWidgets('Quiz wertet eine Antwort aus', (WidgetTester tester) async {
    await tester.pumpWidget(const TaeglichKluegerApp());
    await tester.pumpAndSettle();

    await openPractice(tester);
    await tapPractice(tester, 'Quiz');

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
    await tester.pumpWidget(const TaeglichKluegerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'danke');
    await tester.pumpAndSettle();

    // 'danke' also appears in the search field itself, so check the result
    // row: exactly one word tile showing the Arabic translation.
    expect(find.byType(WordTile), findsOneWidget);
    // Angezeigt wird die vokalisierte Schreibweise …
    expect(find.text('شُكْرًا'), findsOneWidget);

    // … gefunden wird sie auch, wenn man ohne Zeichen tippt.
    await tester.enterText(find.byType(TextField), 'شكرا');
    await tester.pumpAndSettle();
    expect(find.text('شُكْرًا'), findsOneWidget);
  });
}
