import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/build_word_screen.dart';
import 'package:ipa_testing_github_action/screens/home_screen.dart';
import 'package:ipa_testing_github_action/screens/practice_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/session_plan.dart';
import 'package:ipa_testing_github_action/widgets/learning_settings.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<LearningState> frisch() async {
    final LearningState state = LearningState(store: ProgressStore());
    await state.load();
    return state;
  }

  group('Der Block statt der Drohung', () {
    test('ein frischer Lernstand hat genau blockSize offene Wörter', () async {
      final LearningState state = await frisch();
      expect(state.blockSize, kDefaultBlockSize);
      expect(state.currentBlock, hasLength(kDefaultBlockSize));
      expect(state.blockNumber, 1);
      expect(state.blockLearned, 0);
    });

    test('keine Wiederholung ist fällig, solange nichts angefangen ist',
        () async {
      // Das ist der Kern: `dueCount` zählt auch nie angesehene Wörter und
      // stand deshalb auf 793. `repetitionsDue` zählt nur, was wirklich
      // ansteht.
      final LearningState state = await frisch();
      expect(state.repetitionsDue(), isEmpty);
      expect(state.dueCount, greaterThan(700),
          reason: 'die alte Zahl gibt es noch, sie steht nur nicht mehr da');
    });

    test('der Block rückt weiter, wenn Wörter sitzen', () async {
      final LearningState state = await frisch();
      final List<VocabEntry> ersterBlock = state.currentBlock;

      // Ein Wort so oft richtig, bis es sitzt.
      for (int i = 0; i < 6; i++) {
        state.promote(ersterBlock.first);
      }
      expect(state.isLearned(ersterBlock.first), isTrue);

      expect(state.blockLearned, 1);
      expect(state.currentBlock, hasLength(kDefaultBlockSize));
      expect(state.currentBlock.map((VocabEntry e) => e.id),
          isNot(contains(ersterBlock.first.id)),
          reason: 'was sitzt, ist nicht mehr im Block');
    });

    test('nach blockSize gelernten Wörtern ist der nächste Block dran',
        () async {
      final LearningState state = await frisch();
      for (final VocabEntry wort in state.currentBlock.toList()) {
        for (int i = 0; i < 6; i++) {
          state.promote(wort);
        }
      }
      expect(state.blockNumber, 2);
      expect(state.blockLearned, 0);
    });

    test('die Blockzahl passt zum Bestand', () async {
      final LearningState state = await frisch();
      expect(state.blockCount,
          (state.totalCount + state.blockSize - 1) ~/ state.blockSize);
      expect(state.blockProgress, 0);
    });
  });

  group('Woran gearbeitet wird', () {
    test('frisch ist es genau der Block', () async {
      final LearningState state = await frisch();
      expect(state.workingSet.map((VocabEntry e) => e.id),
          state.currentBlock.map((VocabEntry e) => e.id));
    });

    test('fällige Wiederholungen kommen dazu und stehen vorn', () async {
      DateTime jetzt = DateTime(2026, 5, 1);
      final LearningState state =
          LearningState(store: ProgressStore(), clock: () => jetzt);
      await state.load();

      final VocabEntry spaet = state.activeEntries.last;
      state.promote(spaet); // Termin: morgen
      jetzt = DateTime(2026, 5, 8);

      final List<VocabEntry> arbeit = state.workingSet;
      expect(arbeit.first.id, spaet.id, reason: 'fällig zuerst');
      expect(arbeit.length, state.blockSize + 1);
    });

    test('kein Wort steht doppelt darin', () async {
      DateTime jetzt = DateTime(2026, 5, 1);
      final LearningState state =
          LearningState(store: ProgressStore(), clock: () => jetzt);
      await state.load();

      // Ein Wort aus dem laufenden Block fällig machen.
      state.promote(state.currentBlock.first);
      jetzt = DateTime(2026, 5, 8);

      final List<String> ids = <String>[
        for (final VocabEntry e in state.workingSet) e.id,
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('sitzt alles, greift eine Übung wieder ins ganze Fach', () async {
      final LearningState state = await frisch();
      // Alle Wörter als gelernt eintragen.
      for (final VocabEntry e in state.activeEntries) {
        for (int i = 0; i < 6; i++) {
          state.promote(e);
        }
      }
      expect(state.currentBlock, isEmpty);
      expect(state.workingSet, isEmpty);
      // Ein leerer Vorrat wäre eine Übung ohne Aufgaben.
      expect(state.dailySelection(), isNotEmpty);
    });
  });

  group('Kurzrunde nach Maß', () {
    test('standardmäßig alle Arten und drei Blöcke', () async {
      final LearningState state = await frisch();
      expect(state.sessionKinds, ExerciseKind.values.toSet());
      expect(state.sessionBlocks, kBlocksPerSession);
    });

    test('die Auswahl übersteht einen Neustart', () async {
      final LearningState erst = await frisch();
      await erst.setSessionKinds(<ExerciseKind>{
        ExerciseKind.quiz,
        ExerciseKind.tippen,
      });
      await erst.setSessionBlocks(5);
      await erst.setBlockSize(20);

      final LearningState wieder = LearningState(store: ProgressStore());
      await wieder.load();
      expect(wieder.sessionKinds,
          <ExerciseKind>{ExerciseKind.quiz, ExerciseKind.tippen});
      expect(wieder.sessionBlocks, 5);
      expect(wieder.blockSize, 20);
      expect(wieder.currentBlock, hasLength(20));
    });

    test('eine leere Auswahl wird nicht angenommen', () async {
      // Eine Kurzrunde ohne Übung wäre ein Knopf, der ins Leere führt.
      final LearningState state = await frisch();
      await state.setSessionKinds(<ExerciseKind>{});
      expect(state.sessionKinds, ExerciseKind.values.toSet());
    });

    test('ein alter Stand ohne die Felder bekommt alle Arten', () async {
      // Sonst stünde jede bestehende Installation nach dem Update vor einer
      // Kurzrunde ohne Inhalt.
      const String alt = '{"answered":42,"dailyGoal":10,"history":{},'
          '"words":{}}';
      final StoredProgress stand = ProgressStore.decode(alt);
      expect(stand.sessionKinds, isEmpty);
      expect(stand.blockSize, 0);

      final ProgressStore store = ProgressStore();
      await store.save(stand);
      final LearningState state = LearningState(store: store);
      await state.load();
      expect(state.sessionKinds, ExerciseKind.values.toSet());
      expect(state.blockSize, kDefaultBlockSize);
    });

    testWidgets('das Zahnrad führt zu den Einstellungen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      await tester.pumpWidget(
          wrapScreen(const PracticeScreen(), state: state));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Kurzrunde einstellen'));
      await tester.pumpAndSettle();

      expect(find.byType(LearningSettingsSheet), findsOneWidget);
      expect(find.text('Wörter je Block'), findsOneWidget);
      expect(find.text('Kurzrunde'), findsWidgets);
    });

    testWidgets('eine Art abwählen wirkt sofort',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      await tester.pumpWidget(
          wrapScreen(const PracticeScreen(), state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kurzrunde einstellen'));
      await tester.pumpAndSettle();

      // „Zuordnen" steht auch auf der Übungskachel dahinter — gemeint ist
      // das Häkchen im Blatt.
      await tester.tap(find.descendant(
        of: find.byType(LearningSettingsSheet),
        matching: find.text(ExerciseKind.zuordnen.label),
      ));
      await tester.pumpAndSettle();
      expect(state.sessionKinds, isNot(contains(ExerciseKind.zuordnen)));
      expect(state.sessionKinds, hasLength(ExerciseKind.values.length - 1));
    });
  });

  group('Wort bauen verrät die Lösung nicht mehr', () {
    testWidgets('die Lautschrift steht erst auf Wunsch da',
        (WidgetTester tester) async {
      final LearningState state = await frisch();
      final VocabEntry wort = state.activeEntries
          .firstWhere(BuildWordScreen.isSuitable);

      await tester.pumpWidget(wrapScreen(
        BuildWordScreen(entries: <VocabEntry>[wort], title: 'Test'),
        state: state,
      ));
      await tester.pumpAndSettle();

      // „siebzig / sab'un" war Buchstabe für Buchstabe die Bauanleitung.
      expect(find.text(wort.transliteration), findsNothing);
      expect(find.text('Lautschrift zeigen'), findsOneWidget);

      await tester.tap(find.text('Lautschrift zeigen'));
      await tester.pumpAndSettle();
      expect(find.text(wort.transliteration), findsOneWidget);
      expect(find.text('Lautschrift zeigen'), findsNothing);
    });

    testWidgets('das deutsche Wort steht immer da',
        (WidgetTester tester) async {
      final LearningState state = await frisch();
      final VocabEntry wort = state.activeEntries
          .firstWhere(BuildWordScreen.isSuitable);

      await tester.pumpWidget(wrapScreen(
        BuildWordScreen(entries: <VocabEntry>[wort], title: 'Test'),
        state: state,
      ));
      await tester.pumpAndSettle();
      expect(find.text(wort.german), findsOneWidget);
    });
  });

  group('Die Startseite zeigt den Block', () {
    testWidgets('statt der Zahl, die nie kleiner wurde',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final LearningState state = await frisch();
      await tester.pumpWidget(wrapScreen(const HomeScreen(), state: state));
      await tester.pumpAndSettle();

      expect(find.textContaining('Wörter warten'), findsNothing);
      expect(
        find.text('Block 1 von ${state.blockCount} · '
            '0 von ${state.blockSize} sitzen'),
        findsOneWidget,
      );
      expect(find.text('Keine Wiederholung fällig.'), findsOneWidget);
      expect(find.text('Block 1 üben'), findsOneWidget);
    });
  });
}
