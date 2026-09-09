import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/state/reminders.dart';

/// Ein Ersatz für das Benachrichtigungssystem: merkt sich, was geplant wurde.
class FakeReminderBackend implements ReminderBackend {
  FakeReminderBackend({this.permission = true});

  final bool permission;
  final List<PlannedReminder> scheduled = <PlannedReminder>[];
  int cancels = 0;
  int permissionRequests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<void> schedule(PlannedReminder reminder) async =>
      scheduled.add(reminder);

  @override
  Future<void> cancelAll() async {
    cancels++;
    scheduled.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  ReminderService serviceAt(DateTime now, {FakeReminderBackend? backend}) =>
      ReminderService(
        backend: backend ?? FakeReminderBackend(),
        clock: () => now,
      );

  group('Erinnerungsplan', () {
    test('plant die nächsten 14 Tage', () async {
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 8));
      await service.load();

      final List<PlannedReminder> plan =
          service.plan(goalReachedToday: false);
      expect(plan.length, ReminderService.horizonDays);
      expect(plan.first.when, DateTime(2026, 5, 1, 19));
      expect(plan.last.when, DateTime(2026, 5, 14, 19));
    });

    test('heute bleibt still, wenn das Ziel schon geschafft ist', () async {
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 8));
      await service.load();

      final List<PlannedReminder> plan = service.plan(goalReachedToday: true);
      expect(plan.length, ReminderService.horizonDays - 1);
      expect(plan.first.when, DateTime(2026, 5, 2, 19));
    });

    test('eine Uhrzeit, die heute vorbei ist, wird übersprungen', () async {
      // 20 Uhr — die 19-Uhr-Erinnerung von heute ist durch.
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 20));
      await service.load();

      final List<PlannedReminder> plan =
          service.plan(goalReachedToday: false);
      expect(plan.first.when, DateTime(2026, 5, 2, 19));
    });

    test('die heutige Erinnerung nennt die fälligen Wörter', () async {
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 8));
      await service.load();

      final PlannedReminder today =
          service.plan(goalReachedToday: false, dueCount: 12).first;
      expect(today.body, contains('12'));
      expect(today.title, contains('Serie'));
    });

    test('jede Erinnerung hat eine eigene Kennung', () async {
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 8));
      await service.load();
      final List<PlannedReminder> plan =
          service.plan(goalReachedToday: false);
      expect(plan.map((PlannedReminder r) => r.id).toSet().length, plan.length);
    });
  });

  group('Ein- und Ausschalten', () {
    test('ohne Erlaubnis bleibt die Erinnerung aus', () async {
      final FakeReminderBackend backend =
          FakeReminderBackend(permission: false);
      final ReminderService service =
          serviceAt(DateTime(2026, 5, 1, 8), backend: backend);
      await service.load();

      final bool ok = await service.enable(goalReachedToday: false);
      expect(ok, isFalse);
      expect(service.enabled, isFalse);
      expect(backend.scheduled, isEmpty);
    });

    test('mit Erlaubnis werden die Tage geplant', () async {
      final FakeReminderBackend backend = FakeReminderBackend();
      final ReminderService service =
          serviceAt(DateTime(2026, 5, 1, 8), backend: backend);
      await service.load();

      final bool ok = await service.enable(goalReachedToday: false);
      expect(ok, isTrue);
      expect(service.enabled, isTrue);
      expect(backend.scheduled.length, ReminderService.horizonDays);
    });

    test('Ausschalten löscht alle geplanten Erinnerungen', () async {
      final FakeReminderBackend backend = FakeReminderBackend();
      final ReminderService service =
          serviceAt(DateTime(2026, 5, 1, 8), backend: backend);
      await service.load();
      await service.enable(goalReachedToday: false);

      await service.disable();
      expect(service.enabled, isFalse);
      expect(backend.scheduled, isEmpty);
    });

    test('ausgeschaltet wird nichts geplant', () async {
      final FakeReminderBackend backend = FakeReminderBackend();
      final ReminderService service =
          serviceAt(DateTime(2026, 5, 1, 8), backend: backend);
      await service.load();

      await service.refresh(goalReachedToday: false);
      expect(backend.scheduled, isEmpty);
    });

    test('Uhrzeit und Zustand werden gemerkt', () async {
      final ReminderService first = serviceAt(DateTime(2026, 5, 1, 8));
      await first.load();
      await first.enable(goalReachedToday: false);
      await first.setTime(7, 30, goalReachedToday: false);
      expect(first.timeLabel, '07:30');

      // Neue Instanz, wie nach einem Neustart.
      final ReminderService second = serviceAt(DateTime(2026, 5, 1, 8));
      await second.load();
      expect(second.enabled, isTrue);
      expect(second.hour, 7);
      expect(second.minute, 30);
    });
  });
}
