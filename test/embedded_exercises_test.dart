import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/build_word_screen.dart';
import 'package:ipa_testing_github_action/screens/flashcard_screen.dart';
import 'package:ipa_testing_github_action/screens/matching_screen.dart';
import 'package:ipa_testing_github_action/screens/quiz_screen.dart';
import 'package:ipa_testing_github_action/screens/typing_screen.dart';

import 'helpers.dart';

/// Die fünf Übungen als Block einer Kurzrunde.
///
/// Geprüft wird der Vertrag, auf dem die Kette steht: kürzere Runde, kein
/// eigenes Gerüst, am Ende eine Meldung statt einer eigenen Bilanz. Bricht
/// einer davon, bleibt die Kurzrunde stehen — im Test wie auf dem Gerät.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  List<VocabEntry> kurz(bool Function(VocabEntry) passt, int n) =>
      <VocabEntry>[
        ...kAllEntries.where(passt).take(n),
      ];

  Widget eingebettet(Widget kind) => wrapScreen(
        Scaffold(appBar: AppBar(title: const Text('Rahmen')), body: kind),
      );

  group('Eingebettet', () {
    testWidgets('bringt keine zweite Kopfzeile mit', (WidgetTester tester) async {
      final List<VocabEntry> pool = kAllEntries.take(6).toList();
      for (final Widget uebung in <Widget>[
        FlashcardScreen(entries: pool, title: 'x', count: 2, embedded: true),
        QuizScreen(entries: pool, title: 'x', count: 2, embedded: true),
        MatchingScreen(entries: pool, title: 'x', count: 4, embedded: true),
        BuildWordScreen(
            entries: kurz(BuildWordScreen.isSuitable, 4),
            title: 'x',
            count: 2,
            embedded: true),
        TypingScreen(
            entries: kurz(TypingScreen.isSuitable, 4),
            title: 'x',
            count: 2,
            embedded: true),
      ]) {
        await tester.pumpWidget(eingebettet(uebung));
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), findsOneWidget,
            reason: uebung.runtimeType.toString());
      }
    });

    testWidgets('kürzt die Runde auf die verlangte Zahl',
        (WidgetTester tester) async {
      await tester.pumpWidget(eingebettet(FlashcardScreen(
          entries: kAllEntries.take(30).toList(),
          title: 'x',
          count: 2,
          embedded: true)));
      await tester.pumpAndSettle();
      expect(find.text('Karte 1 von 2'), findsOneWidget);

      await tester.pumpWidget(eingebettet(QuizScreen(
          entries: kAllEntries.take(30).toList(),
          title: 'x',
          count: 2,
          embedded: true)));
      await tester.pumpAndSettle();
      expect(find.text('Frage 1 von 2'), findsOneWidget);
    });
  });

  group('Meldet sich, wenn der Block durch ist', () {
    testWidgets('Karteikarten', (WidgetTester tester) async {
      int gemeldet = 0;
      await tester.pumpWidget(eingebettet(FlashcardScreen(
        entries: kAllEntries.take(10).toList(),
        title: 'x',
        count: 1,
        embedded: true,
        onFinished: () => gemeldet++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zum Aufdecken tippen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kann ich'));
      await tester.pumpAndSettle();

      expect(gemeldet, 1);
      // Keine eigene Bilanz — die gehört dem Rahmen.
      expect(find.text('Stapel geschafft!'), findsNothing);
    });

    testWidgets('Quiz', (WidgetTester tester) async {
      int gemeldet = 0;
      await tester.pumpWidget(eingebettet(QuizScreen(
        entries: kAllEntries.take(10).toList(),
        title: 'x',
        count: 1,
        embedded: true,
        onFinished: () => gemeldet++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ergebnis ansehen'));
      await tester.pumpAndSettle();

      expect(gemeldet, 1);
      expect(find.textContaining('richtig'), findsNothing);
    });

    testWidgets('Zuordnen', (WidgetTester tester) async {
      int gemeldet = 0;
      final List<VocabEntry> pool = kKnowledgeEntries
          .where(MatchingScreen.isSuitable)
          .take(4)
          .toList();
      await tester.pumpWidget(eingebettet(MatchingScreen(
        entries: pool,
        title: 'x',
        count: 4,
        embedded: true,
        onFinished: () => gemeldet++,
      )));
      await tester.pumpAndSettle();

      for (final VocabEntry entry in pool) {
        await tester.tap(find.text(entry.german).first, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.answer).first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      expect(gemeldet, greaterThanOrEqualTo(1));
      expect(find.text('Alle Paare gefunden!'), findsNothing);
    });

    testWidgets('Tippen', (WidgetTester tester) async {
      int gemeldet = 0;
      await tester.pumpWidget(eingebettet(TypingScreen(
        entries: kurz(TypingScreen.isSuitable, 6),
        title: 'x',
        count: 1,
        embedded: true,
        onFinished: () => gemeldet++,
      )));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'irgendwas');
      await tester.tap(find.text('Prüfen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ergebnis ansehen'));
      await tester.pumpAndSettle();

      expect(gemeldet, 1);
      expect(find.textContaining('getroffen'), findsNothing);
    });

    testWidgets('Wort bauen', (WidgetTester tester) async {
      int gemeldet = 0;
      await tester.pumpWidget(eingebettet(BuildWordScreen(
        entries: kurz(BuildWordScreen.isSuitable, 6),
        title: 'x',
        count: 1,
        embedded: true,
        onFinished: () => gemeldet++,
      )));
      await tester.pumpAndSettle();

      // Alle Buchstaben der Reihe nach antippen — richtig oder falsch ist
      // hier gleich, geprüft wird die Übergabe.
      final int kacheln = find.byType(InkWell).evaluate().length;
      for (int i = 0; i < kacheln; i++) {
        final Finder frei = find.byType(InkWell);
        if (frei.evaluate().length <= i) break;
        await tester.tap(frei.at(i), warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Der „Prüfen"-Knopf trägt selbst ein InkWell, kann also schon von der
      // Schleife oben getroffen worden sein — dann steht dort bereits das
      // Ergebnis.
      final Finder pruefen = find.widgetWithText(FilledButton, 'Prüfen');
      if (pruefen.evaluate().isNotEmpty) {
        await tester.tap(pruefen);
        await tester.pumpAndSettle();
      }
      expect(find.text('Ergebnis ansehen'), findsOneWidget);
      await tester.tap(find.text('Ergebnis ansehen'));
      await tester.pumpAndSettle();

      expect(gemeldet, 1);
      expect(find.textContaining('gebaut'), findsNothing);
    });
  });
}
