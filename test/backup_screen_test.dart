import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/screens/achievements_screen.dart';
import 'package:ipa_testing_github_action/state/backup.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';

import 'backup_test.dart' show FakeBackupBackend;
import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<LearningState> frisch() async {
    final LearningState state = LearningState(store: ProgressStore());
    await state.load();
    return state;
  }

  Future<void> oeffneMenue(
    WidgetTester tester, {
    required LearningState state,
    required BackupBackend backend,
    required String eintrag,
  }) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrapScreen(
      BackupScope(
        service: BackupService(
            backend: backend, clock: () => DateTime(2026, 10, 4)),
        child: const AchievementsScreen(),
      ),
      state: state,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(eintrag));
    await tester.pumpAndSettle();
  }

  testWidgets('„Lernstand sichern" gibt die Datei heraus',
      (WidgetTester tester) async {
    final LearningState state = await frisch();
    await state.setDailyGoal(14);
    final FakeBackupBackend backend = FakeBackupBackend();

    await oeffneMenue(tester,
        state: state, backend: backend, eintrag: 'Lernstand sichern');

    expect(backend.geschriebenerName, 'taeglich-klueger-2026-10-04.json');
    expect(readBackup(backend.geschriebenerInhalt!)!.dailyGoal, 14);
    expect(find.textContaining('Sicherung herausgegeben'), findsOneWidget);
  });

  testWidgets('Einspielen fragt erst und ersetzt dann',
      (WidgetTester tester) async {
    final LearningState state = await frisch();
    const StoredProgress fremd = StoredProgress(answered: 412, xp: 1840);
    final FakeBackupBackend backend = FakeBackupBackend(
        zumLesen: makeBackup(fremd, DateTime(2026, 10, 1)));

    await oeffneMenue(tester,
        state: state, backend: backend, eintrag: 'Sicherung einspielen');

    expect(find.text('Sicherung einspielen?'), findsOneWidget);
    expect(state.answered, 0, reason: 'vor dem Ja passiert nichts');

    await tester.tap(find.text('Einspielen'));
    await tester.pumpAndSettle();
    expect(state.answered, 412);
    expect(state.xp, 1840);
  });

  testWidgets('„Abbrechen" lässt den Lernstand in Ruhe',
      (WidgetTester tester) async {
    final LearningState state = await frisch();
    final FakeBackupBackend backend = FakeBackupBackend(
        zumLesen: makeBackup(
            const StoredProgress(answered: 412), DateTime(2026, 10, 1)));

    await oeffneMenue(tester,
        state: state, backend: backend, eintrag: 'Sicherung einspielen');
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(state.answered, 0);
  });

  testWidgets('eine fremde Datei wird benannt, nicht eingespielt',
      (WidgetTester tester) async {
    final LearningState state = await frisch();

    await oeffneMenue(tester,
        state: state,
        backend: FakeBackupBackend(zumLesen: '{"irgendwas": true}'),
        eintrag: 'Sicherung einspielen');

    expect(find.text('Sicherung einspielen?'), findsNothing,
        reason: 'gar nicht erst fragen');
    expect(find.textContaining('keine Sicherung'), findsOneWidget);
    expect(state.answered, 0);
  });
}
