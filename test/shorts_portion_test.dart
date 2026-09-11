import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/models/subject.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/shorts_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/reward_store.dart';
import 'package:ipa_testing_github_action/widgets/portion_done.dart';

import 'helpers.dart';

Future<void> _wischen(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(0, -400), 1200);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final VocabCategory thema = kKnowledgeCategories.first;

  Future<(LearningState, RewardStore)> aufbauen(
    WidgetTester tester, {
    int schonHeute = 0,
    int tagesziel = 10,
    RewardStore? speicher,
    VocabCategory? welches,
    double scale = 1,
    Size groesse = const Size(420, 900),
  }) async {
    tester.view.physicalSize = groesse;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final LearningState state = LearningState(store: ProgressStore());
    await state.load();
    await state.setSubject(Subject.wissen);
    await state.setDailyGoal(tagesziel);

    final RewardStore rewards = speicher ?? RewardStore();
    await rewards.load();
    if (schonHeute > 0) await rewards.reportShorts(schonHeute);

    await tester.pumpWidget(scale == 1
        ? wrapScreen(ShortsScreen(category: welches ?? thema),
            state: state, rewards: rewards)
        : wrapScreenScaled(ShortsScreen(category: welches ?? thema),
            scale: scale, state: state, rewards: rewards));
    await tester.pumpAndSettle();
    return (state, rewards);
  }

  group('Gezählt wird die Karte', () {
    testWidgets('die erste zählt beim Öffnen', (WidgetTester tester) async {
      // Sonst wäre genau eine Karte am Tag immer gratis.
      final (_, RewardStore rewards) = await aufbauen(tester);
      expect(rewards.shortsToday, 1);
    });

    testWidgets('jede gewischte Karte zählt dazu',
        (WidgetTester tester) async {
      final (_, RewardStore rewards) = await aufbauen(tester);
      await _wischen(tester);
      await _wischen(tester);
      expect(rewards.shortsToday, 3);
    });

    testWidgets('zurück und wieder vor zählt nicht doppelt',
        (WidgetTester tester) async {
      // Sonst wäre die Portion mit zweimal Wischen aufgebraucht.
      final (_, RewardStore rewards) = await aufbauen(tester);
      await _wischen(tester);
      expect(rewards.shortsToday, 2);

      await tester.fling(find.byType(PageView), const Offset(0, 400), 1200);
      await tester.pumpAndSettle();
      await _wischen(tester);
      expect(rewards.shortsToday, 2);
    });
  });

  group('Die Grenze', () {
    testWidgets('ein neues Thema bleibt zu, wenn die Portion durch ist',
        (WidgetTester tester) async {
      final (LearningState state, _) =
          await aufbauen(tester, schonHeute: 20, tagesziel: 10);
      expect(state.dosePerRound, 20);

      expect(find.byType(PortionDone), findsOneWidget);
      expect(find.text('Das war deine Portion'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('knapp darunter geht es noch auf',
        (WidgetTester tester) async {
      await aufbauen(tester, schonHeute: 19, tagesziel: 10);
      expect(find.byType(PortionDone), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('ein begonnenes Thema darf über die Grenze hinaus zu Ende',
        (WidgetTester tester) async {
      // Mitten aus dem Zusammenhang gerissen zu werden wäre Schikane.
      final (_, RewardStore rewards) =
          await aufbauen(tester, schonHeute: 18, tagesziel: 10);
      expect(find.byType(PageView), findsOneWidget);

      for (int i = 0; i < 5; i++) {
        await _wischen(tester);
      }
      expect(rewards.shortsToday, greaterThan(20));
      expect(find.byType(PortionDone), findsNothing,
          reason: 'das laufende Thema bleibt offen');
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('„Trotzdem weiter" öffnet den Feed wirklich',
        (WidgetTester tester) async {
      await aufbauen(tester, schonHeute: 20, tagesziel: 10);
      await tester.tap(find.text('Trotzdem weiter'));
      await tester.pumpAndSettle();

      expect(find.byType(PortionDone), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('die Portion wächst mit dem Tagesziel',
        (WidgetTester tester) async {
      // Wer sich mehr vornimmt, bekommt mehr — eine Zahl, nicht zwei.
      final (LearningState state, _) =
          await aufbauen(tester, schonHeute: 20, tagesziel: 20);
      expect(state.dosePerRound, 40);
      expect(find.byType(PortionDone), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('am nächsten Tag ist die Portion wieder da',
        (WidgetTester tester) async {
      DateTime jetzt = DateTime(2026, 5, 20, 22);
      final RewardStore gestern = RewardStore(clock: () => jetzt);
      await gestern.load();
      await gestern.reportShorts(25);
      expect(gestern.shortsToday, 25);

      jetzt = DateTime(2026, 5, 21, 7);
      final RewardStore heute = RewardStore(clock: () => jetzt);
      await heute.load();
      expect(heute.shortsToday, 0);

      await aufbauen(tester, speicher: heute);
      expect(find.byType(PortionDone), findsNothing);
    });
  });

  group('Die Abschlusskarte hält an', () {
    testWidgets('„Nochmal" fehlt, wenn die Portion aufgebraucht ist',
        (WidgetTester tester) async {
      // Angefangen knapp unter der Grenze, durchgewischt bis ans Ende:
      // Dann ist sie durch, und der Rückweg in den Feed verschwindet.
      await aufbauen(tester, schonHeute: 18, tagesziel: 10);
      for (int i = 0; i < thema.entries.length + 1; i++) {
        if (find.text('Thema durch').evaluate().isNotEmpty) break;
        await _wischen(tester);
      }
      expect(find.text('Thema durch'), findsOneWidget);
      expect(find.text('Nochmal durchgehen'), findsNothing);
      expect(find.textContaining('das war deine Portion'), findsOneWidget);
    });
  });

  group('Layout', () {
    testWidgets('die Stoppkarte passt auf 320 px bei 150 % Schrift',
        (WidgetTester tester) async {
      await aufbauen(
        tester,
        schonHeute: 20,
        tagesziel: 10,
        scale: 1.5,
        groesse: const Size(320, 568),
      );
      expect(find.byType(PortionDone), findsOneWidget);
      // Der Weg hinaus darf nicht unter dem Rand liegen.
      await tester.ensureVisible(find.text('Fertig'));
      await tester.pumpAndSettle();
    });
  });
}
