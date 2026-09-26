import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/state/reminder_texts.dart';
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

  const int slots = 3;

  group('Erinnerungsplan', () {
    test('plant drei Anstöße für jeden der 14 Tage', () async {
      // 06 Uhr — vor dem Morgenanstoß, heute steht also noch alles an.
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();

      final List<PlannedReminder> plan =
          service.plan(goalReachedToday: false);
      expect(plan.length, ReminderService.horizonDays * slots);
      expect(plan.first.when, DateTime(2026, 5, 1, 8));
      expect(plan[1].when, DateTime(2026, 5, 1, 13));
      expect(plan[2].when, DateTime(2026, 5, 1, 19));
      expect(plan.last.when, DateTime(2026, 5, 14, 19));
    });

    test('heute bleibt der ganze Rest still, wenn das Ziel steht', () async {
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();

      final List<PlannedReminder> plan = service.plan(goalReachedToday: true);
      expect(plan.length, (ReminderService.horizonDays - 1) * slots);
      expect(plan.first.when, DateTime(2026, 5, 2, 8));
    });

    test('was heute vorbei ist, entfällt — der Rest des Tages bleibt',
        () async {
      // 14 Uhr: Morgen und Mittag sind durch, der Abend kommt noch.
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 14));
      await service.load();

      final List<PlannedReminder> plan =
          service.plan(goalReachedToday: false);
      expect(plan.first.when, DateTime(2026, 5, 1, 19));
      expect(plan.length, (ReminderService.horizonDays - 1) * slots + 1);
    });

    test('ein abgeschalteter Anstoß fehlt an allen Tagen', () async {
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();
      await service.setSlotEnabled(ReminderSlot.mittags, false,
          goalReachedToday: false);

      final List<PlannedReminder> plan =
          service.plan(goalReachedToday: false);
      expect(plan.length, ReminderService.horizonDays * 2);
      expect(plan.any((PlannedReminder r) => r.when.hour == 13), isFalse);
      expect(service.isOn(ReminderSlot.mittags), isFalse);
      expect(service.labelOf(ReminderSlot.mittags), '13:00',
          reason: 'die Zeit bleibt sichtbar, auch abgeschaltet');
    });

    test('der Abendtermin lässt sich nicht einzeln abschalten', () async {
      // Sonst liefe der Hauptschalter unbemerkt leer.
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();
      await service.setSlotEnabled(ReminderSlot.abends, false,
          goalReachedToday: false);
      expect(service.isOn(ReminderSlot.abends), isTrue);
    });

    test('die gespeicherte Uhrzeit bleibt der Abendtermin', () async {
      // Eine bestehende Installation kennt nur hour/minute — die dürfen ihre
      // Bedeutung nicht verlieren.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'arabisch_lernen.reminder.enabled': true,
        'arabisch_lernen.reminder.hour': 21,
        'arabisch_lernen.reminder.minute': 30,
      });
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();

      expect(service.labelOf(ReminderSlot.abends), '21:30');
      expect(service.labelOf(ReminderSlot.morgens), '08:00');
      final List<PlannedReminder> plan =
          service.plan(goalReachedToday: false);
      expect(plan[2].when, DateTime(2026, 5, 1, 21, 30));
    });

    test('jede Erinnerung hat eine eigene Kennung', () async {
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();
      final List<PlannedReminder> plan =
          service.plan(goalReachedToday: false);
      expect(plan.map((PlannedReminder r) => r.id).toSet().length, plan.length);
    });

    test('der Text wechselt von Tag zu Tag', () async {
      // Vorher stand ab morgen vierzehn Tage lang derselbe Satz.
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();

      final List<PlannedReminder> abends = service
          .plan(goalReachedToday: false)
          .where((PlannedReminder r) => r.when.hour == 19)
          .toList();
      final Set<String> texte =
          abends.map((PlannedReminder r) => r.body).toSet();
      expect(texte.length, greaterThan(4),
          reason: 'vierzehn Abende, nicht vierzehnmal derselbe Satz');
    });

    test('keine Zahl aus dueEntries — die 1101 kommt nicht zurück', () async {
      // Ohne Stand darf gar keine Zahl in der Meldung stehen.
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();

      for (final PlannedReminder r in service.plan(goalReachedToday: false)) {
        expect(RegExp(r'\d').hasMatch(r.body), isFalse,
            reason: 'ohne Lernstand keine erfundene Zahl: ${r.body}');
      }
    });

    test('mit Stand nennt die Meldung ihn auch', () async {
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();

      final List<PlannedReminder> heute = service
          .plan(
            goalReachedToday: false,
            facts: const ReminderFacts(blockNumber: 3, blockOpen: 6),
          )
          .where((PlannedReminder r) => r.when.day == 1)
          .toList();
      expect(heute.any((PlannedReminder r) => r.body.contains('6')), isTrue);
    });

    test('Zahlen stehen nur im heutigen Text', () async {
      // Was in drei Tagen fällig ist, weiß heute niemand.
      final ReminderService service = serviceAt(DateTime(2026, 5, 1, 6));
      await service.load();

      final List<PlannedReminder> spaeter = service
          .plan(
            goalReachedToday: false,
            facts: const ReminderFacts(
                blockNumber: 3, blockOpen: 6, repetitionsDue: 4, streak: 9),
          )
          .where((PlannedReminder r) => r.when.day > 1)
          .toList();
      for (final PlannedReminder r in spaeter) {
        expect(RegExp(r'\d').hasMatch(r.body), isFalse, reason: r.body);
      }
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
          serviceAt(DateTime(2026, 5, 1, 6), backend: backend);
      await service.load();

      final bool ok = await service.enable(goalReachedToday: false);
      expect(ok, isTrue);
      expect(service.enabled, isTrue);
      expect(backend.scheduled.length, ReminderService.horizonDays * slots);
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
