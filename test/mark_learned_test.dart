import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/flashcard_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/word_progress.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<LearningState> frisch() async {
    final LearningState state = LearningState(store: ProgressStore());
    await state.load();
    return state;
  }

  /// Welche der Karten gerade vorn liegt.
  ///
  /// Der Bildschirm mischt den übergebenen Stapel (`trainingOrder`), die
  /// Reihenfolge steht also nicht fest. Geprüft wird deshalb gegen die Karte,
  /// die wirklich zu sehen ist — nicht gegen die erste der Liste.
  VocabEntry gezeigt(List<VocabEntry> karten) => karten.firstWhere(
      (VocabEntry e) => find.text(e.german).evaluate().isNotEmpty);

  group('Wie lange ein Wort bisher brauchte', () {
    test('„Kann ich" schiebt nur eine Stufe weiter', () async {
      // Das ist der Grund für den neuen Weg: Gelernt ist ab Fach 3, und die
      // Termine dazwischen sind 1, 3 und 7 Tage. Ein Wort, das man ohnehin
      // kann, braucht so über eine Woche.
      final LearningState state = await frisch();
      final VocabEntry wort = state.activeEntries.first;

      state.promote(wort);
      expect(state.boxOf(wort), 1);
      expect(state.isLearned(wort), isFalse);

      state.promote(wort);
      expect(state.isLearned(wort), isFalse);

      state.promote(wort);
      expect(state.boxOf(wort), WordProgress.learnedFromBox);
      expect(state.isLearned(wort), isTrue);
    });
  });

  group('Direkt abhaken', () {
    test('setzt das oberste Fach und einen weiten Termin', () async {
      final LearningState state = await frisch();
      final VocabEntry wort = state.activeEntries.first;

      state.markLearned(wort);
      expect(state.boxOf(wort), WordProgress.maxBox);
      expect(state.isLearned(wort), isTrue);
      expect(state.isDue(wort), isFalse, reason: 'für zwei Monate aus dem Weg');
    });

    test('das Wort verlässt den laufenden Block', () async {
      final LearningState state = await frisch();
      final VocabEntry wort = state.currentBlock.first;

      state.markLearned(wort);
      expect(state.currentBlock.map((VocabEntry e) => e.id),
          isNot(contains(wort.id)));
      expect(state.blockLearned, 1);
      expect(state.currentBlock, hasLength(state.blockSize),
          reason: 'der Block füllt sich nach');
    });

    test('setBox stellt genau das vorherige Fach wieder her', () async {
      // Rückgängig darf nicht bei null landen: Wer ein Wort aus Fach 2
      // versehentlich abhakt, soll danach wieder in Fach 2 stehen.
      final LearningState state = await frisch();
      final VocabEntry wort = state.activeEntries.first;
      state.promote(wort);
      state.promote(wort);
      expect(state.boxOf(wort), 2);

      state.markLearned(wort);
      state.setBox(wort, 2);
      expect(state.boxOf(wort), 2);
      expect(state.isLearned(wort), isFalse);
    });
  });

  group('Der Knopf auf der Karteikarte', () {
    testWidgets('hakt das gezeigte Wort ab und blättert weiter',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      final List<VocabEntry> karten = state.activeEntries.take(3).toList();

      await tester.pumpWidget(wrapScreen(
        FlashcardScreen(entries: karten, title: 'Test'),
        state: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Karte 1 von 3'), findsOneWidget);
      final VocabEntry vorn = gezeigt(karten);

      await tester.tap(find.text('Kenn ich schon — abhaken'));
      await tester.pumpAndSettle();

      expect(state.isLearned(vorn), isTrue);
      expect(state.boxOf(vorn), WordProgress.maxBox);
      expect(find.text('Karte 2 von 3'), findsOneWidget);
    });

    testWidgets('„Rückgängig" holt das Wort zurück',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      final List<VocabEntry> karten = state.activeEntries.take(3).toList();

      await tester.pumpWidget(wrapScreen(
        FlashcardScreen(entries: karten, title: 'Test'),
        state: state,
      ));
      await tester.pumpAndSettle();
      final VocabEntry vorn = gezeigt(karten);

      await tester.tap(find.text('Kenn ich schon — abhaken'));
      await tester.pumpAndSettle();
      expect(state.isLearned(vorn), isTrue);

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(state.isLearned(vorn), isFalse);
      expect(state.boxOf(vorn), 0, reason: 'das Wort war vorher in Fach 0');
    });

    testWidgets('zählt nicht als beantwortete Frage',
        (WidgetTester tester) async {
      // Abhaken heißt „das weiß ich schon", nicht „ich habe geübt". Sonst
      // ließe sich das Tagesziel durch Wegklicken erreichen.
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      await tester.pumpWidget(wrapScreen(
        FlashcardScreen(
          entries: state.activeEntries.take(2).toList(),
          title: 'Test',
        ),
        state: state,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kenn ich schon — abhaken'));
      await tester.pumpAndSettle();
      expect(state.answered, 0);
    });

    testWidgets('„Kann ich" bleibt der Hauptweg', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      final List<VocabEntry> karten = state.activeEntries.take(2).toList();
      await tester.pumpWidget(wrapScreen(
        FlashcardScreen(entries: karten, title: 'Test'),
        state: state,
      ));
      await tester.pumpAndSettle();
      final VocabEntry vorn = gezeigt(karten);

      await tester.tap(find.text('Kann ich'));
      await tester.pumpAndSettle();
      expect(state.boxOf(vorn), 1, reason: 'eine Stufe, wie bisher');
      expect(state.isLearned(vorn), isFalse);
    });

    testWidgets('gibt es auch eingebettet in der Kurzrunde',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      final List<VocabEntry> karten = state.activeEntries.take(3).toList();

      await tester.pumpWidget(wrapScreen(
        Scaffold(
          body: FlashcardScreen(
            entries: karten,
            title: 'Test',
            embedded: true,
            onFinished: () {},
          ),
        ),
        state: state,
      ));
      await tester.pumpAndSettle();
      final VocabEntry vorn = gezeigt(karten);

      await tester.tap(find.text('Kenn ich schon — abhaken'));
      await tester.pumpAndSettle();

      expect(state.isLearned(vorn), isTrue);
      expect(find.text('Rückgängig'), findsOneWidget,
          reason: 'die Meldung findet auch hier ein Gerüst');
    });

    testWidgets('bei 320 px und 150 % Schrift bleiben alle drei erreichbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      await tester.pumpWidget(wrapScreenScaled(
        FlashcardScreen(
          entries: state.activeEntries.take(2).toList(),
          title: 'Test',
        ),
        scale: 1.5,
        state: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kenn ich schon — abhaken'), findsOneWidget);
      expect(find.text('Kann ich'), findsOneWidget);
      expect(find.text('Nochmal üben'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'nichts läuft über');
    });
  });
}
