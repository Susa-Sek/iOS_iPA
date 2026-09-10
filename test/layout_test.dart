import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/main.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/achievements_screen.dart';
import 'package:ipa_testing_github_action/screens/alphabet_screen.dart';
import 'package:ipa_testing_github_action/screens/build_word_screen.dart';
import 'package:ipa_testing_github_action/screens/home_screen.dart';
import 'package:ipa_testing_github_action/screens/practice_screen.dart';
import 'package:ipa_testing_github_action/screens/category_screen.dart';
import 'package:ipa_testing_github_action/screens/flashcard_screen.dart';
import 'package:ipa_testing_github_action/screens/matching_screen.dart';
import 'package:ipa_testing_github_action/data/quran_data.dart';
import 'package:ipa_testing_github_action/screens/quiz_screen.dart';
import 'package:ipa_testing_github_action/screens/quran_screen.dart';
import 'package:ipa_testing_github_action/screens/roots_screen.dart';
import 'package:ipa_testing_github_action/screens/sura_screen.dart';
import 'package:ipa_testing_github_action/screens/verbs_screen.dart';
import 'package:ipa_testing_github_action/screens/search_screen.dart';

import 'helpers.dart';

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

Widget _wrap(Widget child) => wrapScreen(child);

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

      testWidgets('Erfolge', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(const AchievementsScreen()));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(ListView), const Offset(0, -700));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Quran-Übersicht', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(const QuranScreen()));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(ListView), const Offset(0, -500));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Sure Wort für Wort', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          // Al-Fātiḥa hat den längsten Vers der sechs Suren.
          await tester.pumpWidget(_wrap(SuraScreen(sura: kSuras.first)));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Verben beugen', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(const VerbsScreen()));
          await tester.pumpAndSettle();
          // Erste Tabelle aufklappen — dort ist die Zeilenbreite am engsten.
          await tester.tap(find.text('schreiben'));
          await tester.pumpAndSettle();
        });
      });

      testWidgets('Wurzeln', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(_wrap(const RootsScreen()));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(ListView), const Offset(0, -600));
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

  // ---- Große Schrift ----------------------------------------------------

  group('Schrift auf 150 Prozent', () {
    const Size size = Size(390, 844);

    Future<void> check(WidgetTester tester, Widget screen,
        {Future<void> Function(WidgetTester)? then}) async {
      await _withSize(tester, size, () async {
        await tester.pumpWidget(wrapScreenScaled(screen));
        await tester.pumpAndSettle();
        if (then != null) await then(tester);
      });
    }

    testWidgets('Startseite', (WidgetTester tester) async {
      await check(tester, const HomeScreen(), then: (WidgetTester t) async {
        await t.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await t.pumpAndSettle();
      });
    });

    testWidgets('Karteikarten', (WidgetTester tester) async {
      await check(
        tester,
        FlashcardScreen(entries: category.entries, title: category.name),
        then: (WidgetTester t) async {
          await t.tap(find.text('Zum Aufdecken tippen'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('Quiz', (WidgetTester tester) async {
      await check(
        tester,
        QuizScreen(entries: category.entries, title: category.name),
        then: (WidgetTester t) async {
          await t.tap(find.byType(OutlinedButton).first);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('Zuordnen', (WidgetTester tester) async {
      await check(tester,
          MatchingScreen(entries: category.entries, title: category.name));
    });

    testWidgets('Üben', (WidgetTester tester) async {
      await check(tester, const PracticeScreen(),
          then: (WidgetTester t) async {
        await t.drag(find.byType(ListView), const Offset(0, -400));
        await t.pumpAndSettle();
      });
    });

    testWidgets('Erfolge', (WidgetTester tester) async {
      await check(tester, const AchievementsScreen(),
          then: (WidgetTester t) async {
        await t.drag(find.byType(ListView), const Offset(0, -400));
        await t.pumpAndSettle();
      });
    });
  });
}
