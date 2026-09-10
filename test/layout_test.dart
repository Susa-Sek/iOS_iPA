import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
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

/// Tippt die erste Antwort im Quiz an — und scrollt vorher hin.
///
/// Der Quizbildschirm ist eine Liste; bei großer Schrift auf kleinen
/// Telefonen füllt die Frage allein das Bild, und die Antworten stehen
/// darunter.
///
/// Von Hand statt mit `dragUntilVisible`: Das ruft am Ende `element(finder)`
/// auf und verlangt damit **genau einen** Treffer — es gibt aber vier
/// Antwortknöpfe. Und `.first` als Ziel scheidet aus, weil ein leerer
/// `.first`-Finder wirft, statt „noch nicht da" zu melden.
Future<void> _tapErsteAntwort(WidgetTester tester) async {
  final Finder antworten = find.byType(OutlinedButton);
  for (int i = 0; antworten.evaluate().isEmpty && i < 20; i++) {
    await tester.drag(
        find.byKey(QuizScreen.bodyKey), const Offset(0, -80));
    await tester.pump();
  }
  await tester.ensureVisible(antworten.first);
  await tester.pumpAndSettle();
  await tester.tap(antworten.first);
  await tester.pumpAndSettle();
}

void main() {
  final VocabCategory category = kCategories.first;

  for (final Size size in _sizes) {
    group('${size.width.toInt()}x${size.height.toInt()}', () {
      testWidgets('Startseite', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          await tester.pumpWidget(const TaeglichKluegerApp());
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
          await _tapErsteAntwort(tester);
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
        then: _tapErsteAntwort,
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

  // ---- Wissenskarten ----------------------------------------------------
  //
  // Die Layouts sind für kurze Wörter gebaut. Wissenskarten bringen ganze
  // Sätze mit — Frage, vier Antworten und eine Erklärung. Geprüft wird
  // deshalb mit den längsten Texten, die im Bestand wirklich vorkommen, auf
  // dem kleinsten Telefon und bei 150 Prozent Schrift.

  group('Wissenskarten mit den längsten Texten', () {
    List<VocabEntry> laengste() {
      final List<VocabEntry> alle = List<VocabEntry>.of(kKnowledgeEntries)
        ..sort((VocabEntry a, VocabEntry b) =>
            (b.prompt.length + b.answer.length + (b.explanation?.length ?? 0))
                .compareTo(a.prompt.length +
                    a.answer.length +
                    (a.explanation?.length ?? 0)));
      return alle.take(12).toList();
    }

    testWidgets('Quiz auf 320 px', (WidgetTester tester) async {
      await _withSize(tester, const Size(320, 568), () async {
        await tester.pumpWidget(
            _wrap(QuizScreen(entries: laengste(), title: 'Wissen')));
        await tester.pumpAndSettle();
        // Erst nach der Antwort erscheint die Erklärung — der Zustand, in
        // dem am meisten Text auf einmal steht.
        await _tapErsteAntwort(tester);
      });
    });

    testWidgets('Quiz bei 150 Prozent Schrift', (WidgetTester tester) async {
      await _withSize(tester, const Size(320, 568), () async {
        await tester.pumpWidget(
            wrapScreenScaled(QuizScreen(entries: laengste(), title: 'Wissen')));
        await tester.pumpAndSettle();
        await _tapErsteAntwort(tester);
      });
    });

    testWidgets('Karteikarten auf 320 px', (WidgetTester tester) async {
      await _withSize(tester, const Size(320, 568), () async {
        await tester.pumpWidget(
            _wrap(FlashcardScreen(entries: laengste(), title: 'Wissen')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zum Aufdecken tippen'));
        await tester.pumpAndSettle();
      });
    });

    testWidgets('Karteikarten bei 150 Prozent Schrift',
        (WidgetTester tester) async {
      await _withSize(tester, const Size(320, 568), () async {
        await tester.pumpWidget(wrapScreenScaled(
            FlashcardScreen(entries: laengste(), title: 'Wissen')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zum Aufdecken tippen'));
        await tester.pumpAndSettle();
      });
    });

    testWidgets('Thema mit Wissenskarten', (WidgetTester tester) async {
      await _withSize(tester, const Size(320, 568), () async {
        await tester.pumpWidget(
            _wrap(CategoryScreen(category: kKnowledgeCategories.first)));
        await tester.pumpAndSettle();
        // Der Bildschirm hat oben eine waagerechte Leiste und darunter die
        // eigentliche Liste — gemeint ist die letzte.
        await tester.drag(find.byType(ListView).last, const Offset(0, -400));
        await tester.pumpAndSettle();
      });
    });
  });
}
