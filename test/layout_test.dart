import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/main.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/alphabet_screen.dart';
import 'package:ipa_testing_github_action/screens/build_word_screen.dart';
import 'package:ipa_testing_github_action/screens/category_screen.dart';
import 'package:ipa_testing_github_action/screens/flashcard_screen.dart';
import 'package:ipa_testing_github_action/screens/matching_screen.dart';
import 'package:ipa_testing_github_action/screens/quiz_screen.dart';
import 'package:ipa_testing_github_action/screens/search_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

/// Phone sizes every screen is checked against. A RenderFlex overflow makes
/// the surrounding test fail, so simply pumping each screen is a real layout
/// check — that is how the first version of the start screen was caught.
const List<Size> _sizes = <Size>[
  Size(320, 568), // kleines Telefon
  Size(390, 844), // übliches Telefon
  Size(430, 932), // großes Telefon
];

Future<void> _withSize(
  WidgetTester tester,
  Size size,
  Future<void> Function() body,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await body();
}

Widget _wrap(Widget child) => LearningScope(
      state: LearningState(),
      child: MaterialApp(home: child),
    );

void main() {
  final VocabCategory category = kCategories.first;

  for (final Size size in _sizes) {
    group('${size.width.toInt()}x${size.height.toInt()}', () {
      testWidgets('Startseite', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(const ArabischLernenApp());
          await tester.pumpAndSettle();
          await tester.drag(
              find.byType(CustomScrollView), const Offset(0, -600));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Thema', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(CategoryScreen(category: category)));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Karteikarten', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(
            FlashcardScreen(entries: category.entries, title: category.name),
          ));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Zum Aufdecken tippen'));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Quiz', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(
            QuizScreen(entries: category.entries, title: category.name),
          ));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(OutlinedButton).first);
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Zuordnen', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(
            MatchingScreen(entries: category.entries, title: category.name),
          ));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Wort bauen', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(
            BuildWordScreen(entries: category.entries, title: category.name),
          ));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Alphabet', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(const AlphabetScreen()));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Alif'));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Suche', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(const SearchScreen()));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'a');
          await tester.pumpAndSettle();
        });
      });
    });
  }
}
