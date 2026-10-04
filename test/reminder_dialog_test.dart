import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/screens/home_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/reminders.dart';
import 'package:ipa_testing_github_action/state/reminder_texts.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> oeffneDialog(WidgetTester tester,
      {required ReminderService reminders, double scale = 1}) async {
    final LearningState state = LearningState(store: ProgressStore());
    await state.load();

    await tester.pumpWidget(scale == 1
        ? wrapScreen(const HomeScreen(), state: state, reminders: reminders)
        : wrapScreenScaled(const HomeScreen(),
            scale: scale, state: state, reminders: reminders));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tägliche Erinnerung').last);
    await tester.pumpAndSettle();
  }

  group('Der Erinnerungsdialog', () {
    testWidgets('zeigt die drei Anstöße mit ihren Zeiten',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final ReminderService reminders =
          ReminderService(backend: FakeReminderBackend());
      await reminders.load();
      await oeffneDialog(tester, reminders: reminders);

      expect(find.text('Morgens'), findsOneWidget);
      expect(find.text('Mittags'), findsOneWidget);
      expect(find.text('Abends'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('13:00'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
    });

    testWidgets('die Azkar stehen mit dabei, aber ohne wählbare Uhrzeit',
        (WidgetTester tester) async {
      // Ihre Zeit kommt aus den Gebetszeiten und wandert mit der
      // Jahreszeit — eine Uhrzeit zum Antippen wäre eine Lüge.
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final ReminderService reminders =
          ReminderService(backend: FakeReminderBackend());
      await reminders.load();
      await oeffneDialog(tester, reminders: reminders);

      expect(find.text('Morgen-Azkar'), findsOneWidget);
      expect(find.text('Abend-Azkar'), findsOneWidget);
      expect(find.text('nach Fajr'), findsOneWidget);
      expect(find.text('nach ʿAsr'), findsOneWidget);

      await tester.tap(find.text('nach Fajr'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'kein Zeitwähler');
    });

    testWidgets('die Azkar-Erinnerung lässt sich abschalten',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final ReminderService reminders =
          ReminderService(backend: FakeReminderBackend());
      await reminders.load();
      await reminders.enable(goalReachedToday: false);
      await oeffneDialog(tester, reminders: reminders);

      expect(reminders.isOn(ReminderSlot.azkarMorgens), isTrue);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();

      expect(reminders.isOn(ReminderSlot.azkarAbends), isFalse);
      expect(reminders.isOn(ReminderSlot.azkarMorgens), isFalse,
          reason: 'die beiden Azkar hängen an einem Schalter');
      expect(reminders.isOn(ReminderSlot.morgens), isTrue,
          reason: 'die Lern-Anstöße bleiben');
    });

    testWidgets('ein Anstoß lässt sich einzeln abschalten',
        (WidgetTester tester) async {
      // Der Weg, auf dem Erinnerungen überleben: eine herausnehmen, statt
      // alles abzuschalten.
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final ReminderService reminders =
          ReminderService(backend: FakeReminderBackend());
      await reminders.load();
      await reminders.enable(goalReachedToday: false);
      await oeffneDialog(tester, reminders: reminders);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(reminders.isOn(ReminderSlot.morgens), isFalse);
      expect(reminders.isOn(ReminderSlot.abends), isTrue,
          reason: 'der Abendtermin bleibt');
    });

    testWidgets('bei 320 px und 150 % Schrift bleibt „Fertig" erreichbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final ReminderService reminders =
          ReminderService(backend: FakeReminderBackend());
      await reminders.load();
      await oeffneDialog(tester, reminders: reminders, scale: 1.5);

      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.text('Morgens'), findsNothing);
    });
  });
}
