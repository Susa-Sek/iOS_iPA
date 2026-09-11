import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/models/subject.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/duel_screen.dart';
import 'package:ipa_testing_github_action/screens/quiz_screen.dart';
import 'package:ipa_testing_github_action/state/duel.dart';
import 'package:ipa_testing_github_action/state/duel_store.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/sharing.dart';

import 'helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Der Bildschirm liest die Zwischenablage vor, damit man den Code nicht
    // von Hand einfügen muss.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, Object?>{'text': _ablage};
      }
      return null;
    });
  });

  Future<(LearningState, DuelStore, FakeShareBackend)> aufbauen(
    WidgetTester tester, {
    Subject subject = Subject.wissen,
  }) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final LearningState state = LearningState(store: ProgressStore());
    await state.load();
    await state.setSubject(subject);
    final DuelStore duels = DuelStore();
    await duels.load();
    final FakeShareBackend backend = FakeShareBackend();

    await tester.pumpWidget(wrapScreen(
      const DuelScreen(),
      state: state,
      duels: duels,
      sharer: Sharer(backend: backend),
    ));
    await tester.pumpAndSettle();
    return (state, duels, backend);
  }

  group('Der Bildschirm', () {
    testWidgets('bietet die drei Wege an', (WidgetTester tester) async {
      await aufbauen(tester);
      expect(find.text('Herausfordern'), findsOneWidget);
      expect(find.text('Duell annehmen'), findsOneWidget);
      expect(find.text('Ergebnis eintragen'), findsOneWidget);
      // Und sagt, dass nichts hochgeladen wird.
      expect(find.textContaining('kein Konto'), findsOneWidget);
    });

    testWidgets('herausfordern spielt und verschickt den Code',
        (WidgetTester tester) async {
      final (_, DuelStore duels, FakeShareBackend backend) =
          await aufbauen(tester);

      await tester.tap(find.text('Herausfordern'));
      await tester.pumpAndSettle();
      expect(find.text('Worüber?'), findsOneWidget);

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(QuizScreen), findsOneWidget);

      // Die Runde durchspielen: immer die erste Antwort.
      for (int i = 0; i < 12; i++) {
        final Finder antworten = find.byType(OutlinedButton).hitTestable();
        if (antworten.evaluate().isEmpty) break;
        await tester.tap(antworten.first);
        await tester.pumpAndSettle();
        final Finder weiter = find.text('Weiter').hitTestable();
        if (weiter.evaluate().isEmpty) break;
        await tester.tap(weiter.first);
        await tester.pumpAndSettle();
      }
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(duels.records, hasLength(1));
      expect(backend.shared, hasLength(1));
      // Der verschickte Text trägt genau den Code des gespeicherten Duells.
      expect(backend.shared.single, contains(duels.records.first.code));
      expect(backend.shared.single, contains('Schaffst du mehr?'));
    });
  });

  group('Ein eingefügter Code', () {
    testWidgets('ohne Duell darin sagt das', (WidgetTester tester) async {
      _ablage = 'Nur ein Gruß, kein Code.';
      await aufbauen(tester);

      await tester.tap(find.text('Duell annehmen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('kein Duell-Code'), findsOneWidget);
    });

    testWidgets('aus einer fremden Version wird erklärt, nicht gespielt',
        (WidgetTester tester) async {
      // Ein Code mit passendem Thema, aber falschem Fingerabdruck: genau
      // der Fall „ihr habt verschiedene App-Versionen".
      final (LearningState state, _, _) = await aufbauen(tester);
      final VocabCategory thema = state.groups.first.categories.first;
      _ablage = encodeDuel(Duel(
        topicId: thema.id,
        seed: 12345,
        count: 10,
        fingerprint: 0xBEEF,
      ));

      await tester.tap(find.text('Duell annehmen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('verschiedene Versionen'), findsOneWidget);
      expect(find.byType(QuizScreen), findsNothing);
    });

    testWidgets('mit passendem Bestand startet dieselbe Runde',
        (WidgetTester tester) async {
      final (LearningState state, _, _) = await aufbauen(tester);
      final VocabCategory thema = state.groups.first.categories.first;
      _ablage = 'Los gehts! ${encodeDuel(Duel(
        topicId: thema.id,
        seed: 4711,
        count: 5,
        fingerprint: fingerprintOf(thema.entries),
      ))}';

      await tester.tap(find.text('Duell annehmen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(find.byType(QuizScreen), findsOneWidget);
      expect(find.textContaining(thema.name), findsWidgets);
    });
  });

  group('Ein eingetragenes Ergebnis', () {
    testWidgets('ohne passendes Duell sagt das', (WidgetTester tester) async {
      _ablage = encodeResult(
          const DuelResult(duelId: 4242, correct: 7, total: 10));
      await aufbauen(tester);

      await tester.tap(find.text('Ergebnis eintragen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('kein Duell'), findsOneWidget);
    });

    testWidgets('wird dem richtigen Duell zugeordnet',
        (WidgetTester tester) async {
      final LearningState state = LearningState(store: ProgressStore());
      await state.load();
      await state.setSubject(Subject.wissen);
      final VocabCategory thema = state.groups.first.categories.first;
      final Duel duell = Duel(
        topicId: thema.id,
        seed: 99,
        count: 10,
        fingerprint: fingerprintOf(thema.entries),
      );

      final DuelStore duels = DuelStore();
      await duels.load();
      await duels.add(DuelRecord(
        code: encodeDuel(duell),
        topicId: thema.id,
        duelId: duell.id,
        own: 8,
        total: 10,
      ));

      _ablage = encodeResult(
          DuelResult(duelId: duell.id, correct: 6, total: 10));

      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrapScreen(
        const DuelScreen(),
        state: state,
        duels: duels,
        sharer: Sharer(backend: FakeShareBackend()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ergebnis eintragen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gewonnen: 8 zu 6'), findsOneWidget);
      expect(duels.records.first.theirs, 6);
      expect(duels.records.first.won, isTrue);
    });
  });

  group('Ohne Teilen-Blatt', () {
    testWidgets('landet der Code in der Zwischenablage',
        (WidgetTester tester) async {
      // Auf einem Gerät ohne Teilen-Ziel darf der Code nicht verloren gehen.
      final FakeShareBackend backend = FakeShareBackend(canShare: false);
      final Sharer sharer = Sharer(backend: backend);
      expect(await sharer.send('TK-TEST'), ShareOutcome.copied);
      expect(backend.copied, <String>['TK-TEST']);
      expect(backend.shared, isEmpty);
    });
  });
}

/// Was gerade in der Zwischenablage liegt.
String _ablage = '';
