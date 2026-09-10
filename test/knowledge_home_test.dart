import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/knowledge/lessons.dart';
import 'package:ipa_testing_github_action/main.dart';
import 'package:ipa_testing_github_action/models/subject.dart';
import 'package:ipa_testing_github_action/screens/home_screen.dart';
import 'package:ipa_testing_github_action/screens/knowledge_home.dart';
import 'package:ipa_testing_github_action/screens/lesson_screen.dart';
import 'package:ipa_testing_github_action/screens/practice_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/lesson_store.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<(LearningState, LessonStore)> wissen({DateTime? jetzt}) async {
    final LearningState state = LearningState();
    await state.load();
    await state.setSubject(Subject.wissen);
    final LessonStore store = LessonStore();
    await store.load();
    return (state, store);
  }

  group('Startseite im Fach Wissen', () {
    testWidgets('zeigt die Lektion des Tages statt eines Lernwegs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (LearningState state, LessonStore store) = await wissen();
      await tester.pumpWidget(wrapScreen(const KnowledgeHome(),
          state: state, lessons: store));
      await tester.pumpAndSettle();

      expect(find.text('Lektion des Tages'), findsOneWidget);
      expect(find.text(kLessons.first.title), findsOneWidget);
      expect(find.text('Fächer'), findsOneWidget);
      // Das Maß ist die Lektion, nicht die Karte.
      expect(find.textContaining('Lektionen'), findsWidgets);
      expect(find.textContaining('fällig'), findsNothing);
      expect(find.textContaining('gelernt'), findsNothing);
    });

    testWidgets('öffnet die Lektion beim Antippen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (LearningState state, LessonStore store) = await wissen();
      await tester.pumpWidget(wrapScreen(const KnowledgeHome(),
          state: state, lessons: store));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lektion des Tages'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);
    });

    testWidgets('erledigte Lektionen zählen im Fach mit',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (LearningState state, LessonStore store) = await wissen();
      await store.markDone(kLessons.first.id);

      await tester.pumpWidget(wrapScreen(const KnowledgeHome(),
          state: state, lessons: store));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 von'), findsWidgets);
      // Die nächste Lektion ist jetzt die zweite.
      expect(find.text(kLessons[1].title), findsOneWidget);
    });
  });

  group('Die Fächer haben verschiedene Startseiten', () {
    testWidgets('Arabisch behält seine, Wissen bekommt die neue',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TaeglichKluegerApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(KnowledgeHome), findsNothing);

      await tester.tap(find.text('Wissen'));
      await tester.pumpAndSettle();

      expect(find.byType(KnowledgeHome), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('unten stehen drei Bereiche', (WidgetTester tester) async {
      await tester.pumpWidget(const TaeglichKluegerApp());
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });
  });

  group('Üben je Fach', () {
    testWidgets('im Wissen gibt es keine Karteikarten',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (LearningState state, LessonStore store) = await wissen();
      await tester.pumpWidget(
          wrapScreen(const PracticeScreen(), state: state, lessons: store));
      await tester.pumpAndSettle();

      expect(find.text('Lektion des Tages'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      // Vokabelwerkzeuge haben hier nichts zu suchen.
      expect(find.text('Karteikarten'), findsNothing);
      expect(find.text('Zuordnen'), findsNothing);
      expect(find.text('Wort bauen'), findsNothing);
      expect(find.text('Kurzrunde'), findsNothing);
      expect(find.text('Alphabet & Zeichen'), findsNothing);
    });

    testWidgets('in Arabisch bleibt alles, wie es war',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final LearningState state = LearningState();
      await state.load();
      await tester.pumpWidget(wrapScreen(const PracticeScreen(), state: state));
      await tester.pumpAndSettle();

      expect(find.text('Karteikarten'), findsOneWidget);
      expect(find.text('Zuordnen'), findsOneWidget);
      expect(find.text('Wort bauen'), findsOneWidget);
      expect(find.text('Kurzrunde'), findsOneWidget);
      expect(find.text('Alphabet & Zeichen'), findsOneWidget);
      expect(find.text('Lektion des Tages'), findsNothing);
    });
  });

  group('Layout', () {
    for (final double scale in <double>[1.0, 1.5]) {
      testWidgets('auf 320 px bei ${(scale * 100).toInt()} Prozent',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final (LearningState state, LessonStore store) = await wissen();
        await tester.pumpWidget(scale == 1.0
            ? wrapScreen(const KnowledgeHome(), state: state, lessons: store)
            : wrapScreenScaled(const KnowledgeHome(),
                state: state, lessons: store));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
      });
    }
  });
}
