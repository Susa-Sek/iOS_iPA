import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/achievements_data.dart';
import 'package:ipa_testing_github_action/models/achievement.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/reward_store.dart';
import 'package:ipa_testing_github_action/widgets/reward_sheet.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Ein Bildschirm hinter dem Wächter — er zeigt selbst nichts an.
  Future<(LearningState, RewardStore)> aufbauen(
    WidgetTester tester, {
    StoredProgress? stand,
    bool schonBenutzt = true,
  }) async {
    final ProgressStore store = ProgressStore();
    if (stand != null) await store.save(stand);
    final LearningState state = LearningState(store: store);
    await state.load();

    final RewardStore rewards = RewardStore();
    // „Frisch" heißt: erster Start nach dem Update. Für die meisten Tests
    // soll der Speicher schon benutzt worden sein.
    if (schonBenutzt) await rewards.markAnnounced(<String>['_start']);
    await rewards.load();

    await tester.pumpWidget(wrapScreen(
      const RewardWatcher(child: Scaffold(body: Text('Inhalt'))),
      state: state,
      rewards: rewards,
    ));
    await tester.pumpAndSettle();
    return (state, rewards);
  }

  group('Ein freigeschaltetes Abzeichen meldet sich', () {
    testWidgets('mit Namen und Beschreibung', (WidgetTester tester) async {
      // Zehn gelernte Wörter schalten „Angefangen" frei.
      final (LearningState state, RewardStore rewards) = await aufbauen(
        tester,
        stand: const StoredProgress(questDays: 1),
      );
      expect(state.achievementStats.questDays, 1);

      final Achievement erwartet = kAchievements
          .firstWhere((Achievement a) => a.id == 'erster_voller_tag');
      expect(find.text('Abzeichen freigeschaltet'), findsOneWidget);
      expect(find.text(erwartet.name), findsOneWidget);
      expect(find.text(erwartet.description), findsOneWidget);
      expect(rewards.wasAnnounced(erwartet.id), isTrue);
    });

    testWidgets('und nur einmal', (WidgetTester tester) async {
      await aufbauen(tester, stand: const StoredProgress(questDays: 1));
      await tester.tap(find.text('Weiter so'));
      await tester.pumpAndSettle();
      expect(find.text('Abzeichen freigeschaltet'), findsNothing);

      // Ein neuer Durchlauf über denselben Speicher meldet nichts mehr.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Abzeichen freigeschaltet'), findsNothing);
    });

    testWidgets('mehrere nacheinander, nie zwei übereinander',
        (WidgetTester tester) async {
      // Sieben volle Tage schalten „Alles erledigt" und „Gründlich" frei.
      await aufbauen(tester, stand: const StoredProgress(questDays: 7));
      expect(find.text('Abzeichen freigeschaltet'), findsOneWidget);

      await tester.tap(find.text('Weiter so'));
      await tester.pumpAndSettle();
      expect(find.text('Abzeichen freigeschaltet'), findsOneWidget);

      await tester.tap(find.text('Weiter so'));
      await tester.pumpAndSettle();
      expect(find.text('Abzeichen freigeschaltet'), findsNothing);
    });
  });

  group('Beim ersten Start nach dem Update', () {
    testWidgets('geht kein Schwall alter Abzeichen hoch',
        (WidgetTester tester) async {
      // Ein Mensch, der die App lange benutzt: viele Abzeichen offen.
      final (_, RewardStore rewards) = await aufbauen(
        tester,
        stand: const StoredProgress(
          answered: 900,
          xp: 12000,
          perfectRounds: 5,
          questDays: 9,
          shortsDone: 12,
          freezesEarned: 3,
        ),
        schonBenutzt: false,
      );

      expect(find.text('Abzeichen freigeschaltet'), findsNothing);
      // Sie gelten als gesehen, nicht als nicht vorhanden.
      expect(rewards.wasAnnounced('erster_voller_tag'), isTrue);
      expect(rewards.wasAnnounced('drei_joker'), isTrue);
    });
  });

  group('Layout', () {
    testWidgets('320 px und 150 Prozent Schrift: der Knopf bleibt erreichbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ProgressStore store = ProgressStore();
      await store.save(const StoredProgress(questDays: 1));
      final LearningState state = LearningState(store: store);
      await state.load();
      final RewardStore rewards = RewardStore();
      await rewards.markAnnounced(<String>['_start']);
      await rewards.load();

      await tester.pumpWidget(wrapScreenScaled(
        const RewardWatcher(child: Scaffold(body: Text('Inhalt'))),
        scale: 1.5,
        state: state,
        rewards: rewards,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Abzeichen freigeschaltet'), findsOneWidget);
      // Der einzige Weg aus dem Blatt heraus darf nicht unter dem Rand
      // liegen — deshalb scrollt es.
      await tester.ensureVisible(find.text('Weiter so'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter so'));
      await tester.pumpAndSettle();
      expect(find.text('Abzeichen freigeschaltet'), findsNothing);
    });
  });

  group('Das Tagesziel meldet sich', () {
    testWidgets('in dem Moment, in dem es fällt',
        (WidgetTester tester) async {
      final (LearningState state, _) = await aufbauen(tester);
      expect(find.text('Tagesziel geschafft'), findsNothing);

      for (int i = 0; i < state.dailyGoal; i++) {
        state.recordAnswer(correct: true);
      }
      await tester.pumpAndSettle();
      expect(find.text('Tagesziel geschafft'), findsOneWidget);
      expect(find.text('Heute erledigt'), findsOneWidget);
    });

    testWidgets('und danach nicht noch einmal', (WidgetTester tester) async {
      final (LearningState state, _) = await aufbauen(tester);
      for (int i = 0; i < state.dailyGoal; i++) {
        state.recordAnswer(correct: true);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter so'));
      await tester.pumpAndSettle();

      state.recordAnswer(correct: true);
      await tester.pumpAndSettle();
      expect(find.text('Tagesziel geschafft'), findsNothing);
    });
  });
}
