import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/knowledge/lessons.dart';
import 'package:ipa_testing_github_action/models/subject.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/lesson_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/lesson_store.dart';

import 'helpers.dart';

/// Spielt die Lektion von vorn bis zum Fazit durch.
Future<void> _durchspielen(WidgetTester tester, {int maxSchritte = 80}) async {
  Future<void> tippen(Finder ziel) async {
    // Auf kleinen Telefonen steht der Knopf unter dem Rand; ohne Hinscrollen
    // ginge der Tipp ins Leere, ohne dass der Test es merkt.
    await tester.ensureVisible(ziel);
    await tester.pumpAndSettle();
    await tester.tap(ziel);
    await tester.pumpAndSettle();
  }

  for (int i = 0; i < maxSchritte; i++) {
    if (find.text('Das nimmst du mit').evaluate().isNotEmpty) return;
    if (find.text('Los geht’s').evaluate().isNotEmpty) {
      await tippen(find.text('Los geht’s'));
    } else if (find.text('Weiter').evaluate().isNotEmpty) {
      await tippen(find.text('Weiter'));
    } else if (find.byType(OutlinedButton).evaluate().isNotEmpty) {
      await tippen(find.byType(OutlinedButton).first);
    } else if (find.byType(ListView).evaluate().isNotEmpty) {
      // Bei großer Schrift auf einem kleinen Telefon sind die Antworten noch
      // nicht gebaut — die Liste scrollt, statt überzulaufen.
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
    } else {
      return;
    }
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final KnowledgeLesson lektion = lessonById('w_wirtschaft.1')!;

  Future<(LearningState, LessonStore)> aufbauen(WidgetTester tester,
      {KnowledgeLesson? welche}) async {
    final LearningState state = LearningState();
    await state.load();
    await state.setSubject(Subject.wissen);
    final LessonStore store = LessonStore();
    await store.load();

    await tester.pumpWidget(wrapScreen(
      LessonScope(
        store: store,
        child: LessonScreen(lesson: welche ?? lektion),
      ),
      state: state,
    ));
    await tester.pumpAndSettle();
    return (state, store);
  }

  group('Ablauf', () {
    testWidgets('beginnt mit dem Einstieg, nicht mit einer Frage',
        (WidgetTester tester) async {
      await aufbauen(tester);
      expect(find.text(lektion.title), findsWidgets);
      expect(find.text(lektion.intro), findsOneWidget);
      expect(find.text('Los geht’s'), findsOneWidget);
    });

    testWidgets('zeigt danach Lesekarten ohne jede Bewertung',
        (WidgetTester tester) async {
      await aufbauen(tester);
      await tester.tap(find.text('Los geht’s'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lesen · 1 von'), findsOneWidget);
      // Das ist der Kern des Umbaus: Hier wird gelesen, nicht eingeschätzt.
      expect(find.text('Kann ich'), findsNothing);
      expect(find.text('Nochmal üben'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
      expect(find.text('Weiter'), findsOneWidget);

      // Begriff, Bedeutung und Erklärung stehen zusammen auf einem Bild.
      final VocabEntry erste = lektion.reading.first;
      expect(find.text(erste.german), findsOneWidget);
      expect(find.text(erste.answer), findsOneWidget);
    });

    testWidgets('prüft erst nach dem Lesen', (WidgetTester tester) async {
      await aufbauen(tester);
      await tester.tap(find.text('Los geht’s'));
      await tester.pumpAndSettle();

      for (int i = 0; i < lektion.reading.length; i++) {
        expect(find.textContaining('Lesen ·'), findsOneWidget,
            reason: 'Lesekarte ${i + 1}');
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Frage 1 von'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNWidgets(4));
    });

    testWidgets('endet mit dem Fazit und den Kernsätzen',
        (WidgetTester tester) async {
      final (LearningState state, LessonStore store) = await aufbauen(tester);
      await _durchspielen(tester);

      expect(find.text('Das nimmst du mit'), findsOneWidget);
      for (final String satz in lektion.takeaway) {
        expect(find.text(satz), findsOneWidget);
      }
      expect(store.isDone(lektion.id), isTrue);
      expect(state.answered, greaterThan(0));
    });

    testWidgets('ohne Nachfassen gibt es keinen Nachfass-Abschnitt',
        (WidgetTester tester) async {
      // Frischer Lernstand: Es gibt keine falsch beantwortete Frage von
      // früher, also fängt die Lektion sofort mit dem Einstieg an.
      await aufbauen(tester);
      expect(find.textContaining('Kurz nachgefasst'), findsNothing);
    });
  });

  group('Nachfassen', () {
    testWidgets('bleibt bei höchstens zwei Fragen',
        (WidgetTester tester) async {
      final LearningState state = LearningState();
      await state.load();
      await state.setSubject(Subject.wissen);
      // Fünf alte Fehler — vorweg kommen trotzdem nur zwei.
      final KnowledgeLesson andere = lessonById('w_medien.1')!;
      for (final VocabEntry e in andere.checks.take(5)) {
        state.demote(e);
      }

      final LessonStore store = LessonStore();
      await store.load();
      await tester.pumpWidget(wrapScreen(
        LessonScope(store: store, child: LessonScreen(lesson: lektion)),
        state: state,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Kurz nachgefasst · 1 von 2'), findsOneWidget);
    });

    testWidgets('holt frühere Fehler an den Anfang',
        (WidgetTester tester) async {
      final LearningState state = LearningState();
      await state.load();
      await state.setSubject(Subject.wissen);

      // Zwei Fragen aus einer anderen Lektion falsch beantwortet.
      final KnowledgeLesson andere = lessonById('w_medien.1')!;
      state.demote(andere.checks[0]);
      state.demote(andere.checks[1]);

      final LessonStore store = LessonStore();
      await store.load();
      await tester.pumpWidget(wrapScreen(
        LessonScope(store: store, child: LessonScreen(lesson: lektion)),
        state: state,
      ));
      await tester.pumpAndSettle();

      // Höchstens zwei — die Wiederholung darf die Lektion nicht auffressen.
      expect(find.text('Kurz nachgefasst · 1 von 2'), findsOneWidget);
    });
  });

  group('Layout', () {
    for (final double scale in <double>[1.0, 1.5]) {
      testWidgets('auf 320 px bei ${(scale * 100).toInt()} Prozent',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Die Lektion mit den längsten Texten im Bestand.
        final KnowledgeLesson lang = kLessons.reduce((KnowledgeLesson a,
                KnowledgeLesson b) =>
            _laenge(a) > _laenge(b) ? a : b);

        final LearningState state = LearningState();
        await state.load();
        await state.setSubject(Subject.wissen);
        final LessonStore store = LessonStore();
        await store.load();

        final Widget screen = LessonScope(
          store: store,
          child: LessonScreen(lesson: lang),
        );
        await tester.pumpWidget(scale == 1.0
            ? wrapScreen(screen, state: state)
            : wrapScreenScaled(screen, state: state));
        await tester.pumpAndSettle();
        await _durchspielen(tester);
        expect(find.text('Das nimmst du mit'), findsOneWidget);
      });
    }
  });
}

int _laenge(KnowledgeLesson lesson) => <int>[
      lesson.intro.length,
      for (final VocabEntry e in lesson.entries)
        e.german.length + e.answer.length + (e.explanation?.length ?? 0),
      for (final String s in lesson.takeaway) s.length,
    ].fold(0, (int a, int b) => a + b);
