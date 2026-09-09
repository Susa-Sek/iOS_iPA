import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/build_word_screen.dart';
import 'package:ipa_testing_github_action/screens/matching_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

import 'helpers.dart';

const List<VocabEntry> _words = <VocabEntry>[
  VocabEntry('Buch', 'كتاب', 'kitab'),
  VocabEntry('Sonne', 'شمس', 'shams'),
  VocabEntry('Mond', 'قمر', 'qamar'),
  VocabEntry('Haus', 'منزل', 'manzil'),
  VocabEntry('Brot', 'خبز', 'khubz'),
  VocabEntry('Wasser', 'ماء', "ma'"),
];

Widget _wrap(Widget child, LearningState state) =>
    wrapScreen(child, state: state);

void main() {
  group('Zuordnen', () {
    testWidgets('ein richtiges Paar wird gelöst und hochgestuft',
        (WidgetTester tester) async {
      final LearningState state = LearningState();
      await tester.pumpWidget(_wrap(
        const MatchingScreen(entries: _words, title: 'Test'),
        state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('0 / ${_words.length} Paare'), findsOneWidget);

      await tester.tap(find.text('Buch'));
      await tester.pump();
      await tester.tap(find.text('كتاب'));
      await tester.pumpAndSettle();

      expect(find.text('1 / ${_words.length} Paare'), findsOneWidget);
      expect(state.boxOf(_words.first), 1);
      expect(state.correct, 1);
    });

    testWidgets('ein falsches Paar zählt als Fehler',
        (WidgetTester tester) async {
      final LearningState state = LearningState();
      state.promote(_words.first);

      await tester.pumpWidget(_wrap(
        const MatchingScreen(entries: _words, title: 'Test'),
        state,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buch'));
      await tester.pump();
      await tester.tap(find.text('شمس'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('0 / ${_words.length} Paare'), findsOneWidget);
      expect(state.boxOf(_words.first), 0);
      expect(state.correct, 0);
      expect(state.answered, 1);
    });
  });

  group('Wort bauen', () {
    testWidgets('ein korrekt gebautes Wort wird angenommen',
        (WidgetTester tester) async {
      final LearningState state = LearningState();
      const VocabEntry word = VocabEntry('Buch', 'كتاب', 'kitab');

      await tester.pumpWidget(_wrap(
        const BuildWordScreen(entries: <VocabEntry>[word], title: 'Test'),
        state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Buch'), findsOneWidget);
      expect(find.text('Wort 1 von 1'), findsOneWidget);

      // The tiles carry the letters of the word, in random order.
      for (final int rune in word.arabic.runes) {
        await tester.tap(find.text(String.fromCharCode(rune)));
        await tester.pump();
      }

      await tester.tap(find.text('Prüfen'));
      await tester.pumpAndSettle();

      expect(state.boxOf(word), 1);
      expect(state.correct, 1);
      expect(find.text('Ergebnis ansehen'), findsOneWidget);
    });

    testWidgets('nur kurze Einzelwörter kommen in die Übung', (
      WidgetTester tester,
    ) async {
      expect(
        BuildWordScreen.isSuitable(const VocabEntry('Buch', 'كتاب', 'kitab')),
        isTrue,
      );
      expect(
        BuildWordScreen.isSuitable(
            const VocabEntry('Guten Morgen', 'صباح الخير', 'sabah al-khayr')),
        isFalse,
      );
      expect(
        BuildWordScreen.isSuitable(const VocabEntry('und', 'و', 'wa')),
        isFalse,
      );
    });
  });
}
