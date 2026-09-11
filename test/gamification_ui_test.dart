import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/main.dart';
import 'package:ipa_testing_github_action/models/subject.dart';
import 'package:ipa_testing_github_action/screens/achievements_screen.dart';
import 'package:ipa_testing_github_action/screens/home_screen.dart';
import 'package:ipa_testing_github_action/screens/knowledge_home.dart';
import 'package:ipa_testing_github_action/state/daily_quests.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/reward_store.dart';
import 'package:ipa_testing_github_action/widgets/quest_card.dart';
import 'package:ipa_testing_github_action/widgets/streak_chip.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<(LearningState, RewardStore)> aufbauen(
    WidgetTester tester,
    Widget screen, {
    Subject subject = Subject.arabisch,
    Size groesse = const Size(420, 1400),
    double scale = 1,
  }) async {
    tester.view.physicalSize = groesse;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final LearningState state = LearningState(store: ProgressStore());
    await state.load();
    await state.setSubject(subject);
    final RewardStore rewards = RewardStore();
    await rewards.load();
    // Im Betrieb verbindet main.dart die beiden; im Test derselbe Griff.
    state.attachQuests(
        (QuestKind kind, int amount) => rewards.report(kind, amount: amount));

    await tester.pumpWidget(scale == 1
        ? wrapScreen(screen, state: state, rewards: rewards)
        : wrapScreenScaled(screen,
            scale: scale, state: state, rewards: rewards));
    await tester.pumpAndSettle();
    return (state, rewards);
  }

  group('Serie und Punkte in der Kopfzeile', () {
    testWidgets('stehen auf beiden Startseiten',
        (WidgetTester tester) async {
      await aufbauen(tester, const HomeScreen());
      expect(find.byType(StreakChip), findsOneWidget);

      await aufbauen(tester, const KnowledgeHome(), subject: Subject.wissen);
      expect(find.byType(StreakChip), findsOneWidget);
    });

    testWidgets('die Flamme brennt erst mit erreichtem Tagesziel',
        (WidgetTester tester) async {
      final (LearningState state, _) =
          await aufbauen(tester, const HomeScreen());
      expect(find.byIcon(Icons.local_fire_department_outlined), findsWidgets);

      for (int i = 0; i < state.dailyGoal; i++) {
        state.recordAnswer(correct: true);
      }
      await tester.pumpAndSettle();
      expect(find.descendant(
        of: find.byType(StreakChip),
        matching: find.byIcon(Icons.local_fire_department),
      ), findsOneWidget);
    });

    testWidgets('Antippen führt zu den Erfolgen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const TaeglichKluegerApp());
      await tester.pumpAndSettle();
      expect(find.byType(AchievementsScreen), findsNothing);

      await tester.tap(find.byType(StreakChip));
      await tester.pumpAndSettle();
      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('große Zahlen sprengen die Kopfzeile nicht',
        (WidgetTester tester) async {
      final (LearningState state, _) = await aufbauen(
        tester,
        const HomeScreen(),
        groesse: const Size(320, 900),
        scale: 1.5,
      );
      // 2.000 richtige Antworten — die Punkte stehen dann fünfstellig da.
      for (int i = 0; i < 2000; i++) {
        state.recordAnswer(correct: true);
      }
      await tester.pumpAndSettle();
      expect(find.byType(StreakChip), findsOneWidget);
    });
  });

  group('Tagesaufgaben', () {
    testWidgets('drei stehen auf der Startseite', (WidgetTester tester) async {
      await aufbauen(tester, const HomeScreen());
      expect(find.byType(QuestCard), findsOneWidget);
      expect(find.text('Tagesaufgaben'), findsOneWidget);
      expect(find.text('0 von 3'), findsOneWidget);
    });

    testWidgets('auch im Wissen', (WidgetTester tester) async {
      await aufbauen(tester, const KnowledgeHome(), subject: Subject.wissen);
      expect(find.byType(QuestCard), findsOneWidget);
    });

    testWidgets('eine Antwort bewegt die zählende Aufgabe',
        (WidgetTester tester) async {
      final (LearningState state, RewardStore rewards) =
          await aufbauen(tester, const HomeScreen());
      state.recordAnswer(correct: true);
      await tester.pumpAndSettle();
      expect(rewards.progressOf(QuestKind.antworten), 1);
      expect(rewards.progressOf(QuestKind.richtige), 1);
    });

    testWidgets('alle drei erledigt bringen einen Jokertag',
        (WidgetTester tester) async {
      final (LearningState state, RewardStore rewards) =
          await aufbauen(tester, const HomeScreen());
      final List<Quest> heute = buildQuests(
        day: DateTime.now(),
        dailyGoal: state.dailyGoal,
        hatArabisch: true,
        hatWissen: true,
      );
      for (final Quest q in heute) {
        await rewards.report(q.kind, amount: q.target);
      }
      await tester.pumpAndSettle();

      expect(state.freezes, 1);
      expect(state.freezesEarned, 1);
      expect(find.text('3 von 3'), findsOneWidget);
      expect(find.textContaining('Jokertag'), findsOneWidget);
    });

    testWidgets('der Joker kommt nur einmal am Tag',
        (WidgetTester tester) async {
      final (LearningState state, RewardStore rewards) =
          await aufbauen(tester, const HomeScreen());
      final List<Quest> heute = buildQuests(
        day: DateTime.now(),
        dailyGoal: state.dailyGoal,
        hatArabisch: true,
        hatWissen: true,
      );
      for (final Quest q in heute) {
        await rewards.report(q.kind, amount: q.target);
      }
      await tester.pumpAndSettle();
      // Noch mehr tun ändert nichts mehr.
      for (final Quest q in heute) {
        await rewards.report(q.kind, amount: q.target);
      }
      await tester.pumpAndSettle();
      expect(state.freezes, 1);
    });

    testWidgets('320 px und 150 Prozent Schrift laufen nicht über',
        (WidgetTester tester) async {
      await aufbauen(
        tester,
        const HomeScreen(),
        groesse: const Size(320, 1600),
        scale: 1.5,
      );
      expect(find.byType(QuestCard), findsOneWidget);
    });
  });
}
