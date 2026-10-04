import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_texts.dart';

/// One planned reminder.
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;

  @override
  String toString() => '#$id $when — $title';
}

/// The part of the notification system the app uses. Behind an interface so
/// the scheduling logic can be tested without a device.
abstract class ReminderBackend {
  Future<void> init();

  /// Asks the system for permission. Returns false when the user declines.
  Future<bool> requestPermission();

  Future<void> schedule(PlannedReminder reminder);

  Future<void> cancelAll();
}

/// The real implementation.
class LocalNotificationsBackend implements ReminderBackend {
  LocalNotificationsBackend([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'daily_reminder';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (error) {
      debugPrint('Benachrichtigungen nicht verfügbar: $error');
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      return false;
    } catch (error) {
      debugPrint('Berechtigung konnte nicht angefragt werden: $error');
      return false;
    }
  }

  @override
  Future<void> schedule(PlannedReminder reminder) async {
    await init();
    try {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
        // Ungenaue Planung reicht für eine Lernerinnerung und erspart die
        // Sonderberechtigung für exakte Alarme.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Tägliche Erinnerung',
            channelDescription:
                'Erinnert einmal am Tag daran, Vokabeln zu wiederholen.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (error) {
      debugPrint('Erinnerung konnte nicht geplant werden: $error');
    }
  }

  @override
  Future<void> cancelAll() async {
    await init();
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('Erinnerungen konnten nicht gelöscht werden: $error');
    }
  }
}

/// Plans the daily reminders.
///
/// Notifications have to be scheduled in advance, but whether the learner is
/// done for today is only known while the app runs. The service therefore
/// plans the next [horizonDays] days individually and simply leaves out a day
/// that is already finished — every app start refreshes the plan.
class ReminderService extends ChangeNotifier {
  ReminderService({
    ReminderBackend? backend,
    SharedPreferences? preferences,
    DateTime Function()? clock,
  })  : _backend = backend ?? LocalNotificationsBackend(),
        _prefs = preferences,
        _now = clock ?? DateTime.now;

  /// Nicht umbenennen — siehe test/naming_test.dart.
  static const String enabledKey = 'arabisch_lernen.reminder.enabled';

  /// Stunde und Minute des **Abendtermins** — die Schlüssel von früher, als
  /// es nur eine Erinnerung am Tag gab. Sie behalten ihre Bedeutung, damit
  /// eine bestehende Installation ihre gewählte Zeit nicht verliert.
  static const String hourKey = 'arabisch_lernen.reminder.hour';
  static const String minuteKey = 'arabisch_lernen.reminder.minute';

  /// Morgen und Mittag als **Minuten seit Mitternacht**, `-1` heißt „aus".
  ///
  /// Eine Zahl statt zweier Schlüssel je Zeit, und das Abschalten steckt in
  /// derselben Zahl: So kommt ein Anstoß weniger ohne einen dritten Schlüssel
  /// aus, der mit den beiden anderen auseinanderlaufen könnte.
  static const String morningKey = 'arabisch_lernen.reminder.morning';
  static const String noonKey = 'arabisch_lernen.reminder.noon';

  /// Ob die beiden Azkar-Anstöße kommen. Ihre **Zeit** steht hier nicht —
  /// die rechnet `lib/state/prayer_times.dart` je Tag aus den Gebetszeiten.
  static const String azkarKey = 'arabisch_lernen.reminder.azkar';

  /// Voreinstellungen: 08:00 und 13:00.
  static const int defaultMorning = 8 * 60;
  static const int defaultNoon = 13 * 60;

  /// Aus.
  static const int slotOff = -1;

  /// How many days ahead are planned.
  static const int horizonDays = 14;

  final ReminderBackend _backend;
  final DateTime Function() _now;
  SharedPreferences? _prefs;

  bool _enabled = false;
  int _hour = 19;
  int _minute = 0;
  int _morning = defaultMorning;
  int _noon = defaultNoon;
  bool _azkar = true;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  String get timeLabel => _label(_hour * 60 + _minute);

  /// Die Uhrzeit eines Anstoßes in Minuten seit Mitternacht, oder `null`,
  /// wenn er abgeschaltet ist.
  int? minutesOf(ReminderSlot slot) {
    final int value = switch (slot) {
      ReminderSlot.morgens => _morning,
      ReminderSlot.mittags => _noon,
      ReminderSlot.abends => _hour * 60 + _minute,
      // Die Azkar haben keine feste Uhrzeit — ihre Zeit kommt je Tag aus
      // den Gebetszeiten und wird [plan] von außen hereingereicht.
      ReminderSlot.azkarMorgens || ReminderSlot.azkarAbends => slotOff,
    };
    return value < 0 ? null : value;
  }

  bool isOn(ReminderSlot slot) =>
      slot.istAzkar ? _azkar : minutesOf(slot) != null;

  /// „08:00" — auch für einen abgeschalteten Anstoß, damit im Menü nicht
  /// plötzlich ein Strich steht, wo eben noch eine Zeit war.
  String labelOf(ReminderSlot slot) => switch (slot) {
        ReminderSlot.morgens => _label(_morning < 0 ? defaultMorning : _morning),
        ReminderSlot.mittags => _label(_noon < 0 ? defaultNoon : _noon),
        ReminderSlot.abends => timeLabel,
        ReminderSlot.azkarMorgens => 'nach Fajr',
        ReminderSlot.azkarAbends => 'nach ʿAsr',
      };

  static String _label(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('Erinnerungs-Einstellungen nicht lesbar: $error');
    }
    _enabled = _prefs?.getBool(enabledKey) ?? false;
    _hour = _prefs?.getInt(hourKey) ?? 19;
    _minute = _prefs?.getInt(minuteKey) ?? 0;
    _morning = _prefs?.getInt(morningKey) ?? defaultMorning;
    _noon = _prefs?.getInt(noonKey) ?? defaultNoon;
    _azkar = _prefs?.getBool(azkarKey) ?? true;
    notifyListeners();
  }

  /// Turns reminders on. Returns false when the system permission is refused,
  /// so the UI can say so instead of promising something that never arrives.
  Future<bool> enable({required bool goalReachedToday}) async {
    final bool granted = await _backend.requestPermission();
    if (!granted) return false;
    _enabled = true;
    await _prefs?.setBool(enabledKey, true);
    notifyListeners();
    await refresh(goalReachedToday: goalReachedToday);
    return true;
  }

  Future<void> disable() async {
    _enabled = false;
    await _prefs?.setBool(enabledKey, false);
    notifyListeners();
    await _backend.cancelAll();
  }

  Future<void> setTime(int hour, int minute,
      {required bool goalReachedToday}) async {
    _hour = hour;
    _minute = minute;
    await _prefs?.setInt(hourKey, hour);
    await _prefs?.setInt(minuteKey, minute);
    notifyListeners();
    if (_enabled) await refresh(goalReachedToday: goalReachedToday);
  }

  /// Die Uhrzeit eines Anstoßes setzen.
  Future<void> setSlotTime(ReminderSlot slot, int hour, int minute,
      {required bool goalReachedToday}) async {
    if (slot == ReminderSlot.abends) {
      return setTime(hour, minute, goalReachedToday: goalReachedToday);
    }
    await _setMinutes(slot, hour * 60 + minute,
        goalReachedToday: goalReachedToday);
  }

  /// Einen Anstoß ab- oder wieder anschalten.
  ///
  /// Der Abendtermin bleibt: Wer alles los sein will, schaltet die Erinnerung
  /// aus — ein Hauptschalter, der unbemerkt leer läuft, wäre schlimmer als
  /// keiner.
  Future<void> setSlotEnabled(ReminderSlot slot, bool on,
      {required bool goalReachedToday}) async {
    if (slot.istAzkar) {
      _azkar = on;
      await _prefs?.setBool(azkarKey, on);
      notifyListeners();
      if (_enabled) await refresh(goalReachedToday: goalReachedToday);
      return;
    }
    if (slot == ReminderSlot.abends) return;
    final int wert = on
        ? (slot == ReminderSlot.morgens
            ? (_morning < 0 ? defaultMorning : _morning)
            : (_noon < 0 ? defaultNoon : _noon))
        : slotOff;
    await _setMinutes(slot, wert, goalReachedToday: goalReachedToday);
  }

  Future<void> _setMinutes(ReminderSlot slot, int minutes,
      {required bool goalReachedToday}) async {
    if (slot == ReminderSlot.morgens) {
      _morning = minutes;
      await _prefs?.setInt(morningKey, minutes);
    } else {
      _noon = minutes;
      await _prefs?.setInt(noonKey, minutes);
    }
    notifyListeners();
    if (_enabled) await refresh(goalReachedToday: goalReachedToday);
  }

  /// Rebuilds the plan: cancel everything, then schedule the coming days.
  Future<void> refresh({
    required bool goalReachedToday,
    ReminderFacts facts = const ReminderFacts(),
    AzkarZeit? azkarZeit,
    Set<ReminderSlot> azkarErledigt = const <ReminderSlot>{},
  }) async {
    if (!_enabled) return;
    await _backend.cancelAll();
    for (final PlannedReminder reminder in plan(
      goalReachedToday: goalReachedToday,
      facts: facts,
      azkarZeit: azkarZeit,
      azkarErledigt: azkarErledigt,
    )) {
      await _backend.schedule(reminder);
    }
  }

  /// The reminders for the coming days — pure, so the tests can check it.
  ///
  /// Drei Anstöße am Tag statt einem, und jeder mit eigenem Text: Vorher stand
  /// ab morgen vierzehn Tage lang derselbe Satz, und daran nutzt sich eine
  /// Erinnerung ab.
  @visibleForTesting
  List<PlannedReminder> plan({
    required bool goalReachedToday,
    ReminderFacts facts = const ReminderFacts(),
    AzkarZeit? azkarZeit,
    Set<ReminderSlot> azkarErledigt = const <ReminderSlot>{},
  }) {
    final DateTime now = _now();
    final List<PlannedReminder> reminders = <PlannedReminder>[];

    for (int day = 0; day < horizonDays; day++) {
      final DateTime date =
          DateTime(now.year, now.month, now.day).add(Duration(days: day));

      for (final ReminderSlot slot in ReminderSlot.values) {
        if (!isOn(slot)) continue;

        // Das Tagesziel bremst die **Lern**-Anstöße. Die Azkar haben damit
        // nichts zu tun: Wer sein Pensum gelernt hat, hat deshalb noch nichts
        // gesprochen — die beiden Spuren berühren sich nicht.
        if (day == 0 && goalReachedToday && !slot.istAzkar) continue;

        final DateTime? when = slot.istAzkar
            ? azkarZeit?.call(slot, date)
            : DateTime(date.year, date.month, date.day)
                .add(Duration(minutes: minutesOf(slot)!));
        // Ohne eingestellten Ort gibt es keine Azkar-Zeit — dann lieber
        // keine Erinnerung als eine zur falschen Stunde.
        if (when == null) continue;

        // Was heute schon gesprochen ist, meldet sich nicht mehr.
        if (day == 0 && azkarErledigt.contains(slot)) continue;

        // Was heute schon vorbei ist, kommt nicht mehr.
        if (day == 0 && !when.isAfter(now)) continue;

        final ReminderText text = buildReminderText(
          day: date,
          slot: slot,
          // Zahlen nur für heute: Was in drei Tagen fällig ist, weiß heute
          // niemand, und eine Zahl, die bis dahin falsch wird, entmutigt
          // mehr, als sie antreibt.
          facts: day == 0 ? facts : facts.ohneZahlen,
        );

        reminders.add(PlannedReminder(
          id: 1000 + day * ReminderSlot.values.length + slot.index,
          when: when,
          title: text.title,
          body: text.body,
        ));
      }
    }
    return reminders;
  }
}

/// Woher die Zeit eines Azkar-Anstoßes an einem bestimmten Tag kommt.
///
/// Eine Funktion und keine Abhängigkeit: So bleibt dieser Dienst frei von
/// `adhan` und von den Azkar-Einstellungen, und `plan()` lässt sich im Test
/// mit festen Zeiten nachrechnen.
typedef AzkarZeit = DateTime? Function(ReminderSlot slot, DateTime tag);

/// Macht den [ReminderService] im Widget-Baum verfügbar.
class ReminderScope extends InheritedNotifier<ReminderService> {
  const ReminderScope({
    super.key,
    required ReminderService service,
    required super.child,
  }) : super(notifier: service);

  static ReminderService of(BuildContext context) {
    final ReminderScope? scope =
        context.dependOnInheritedWidgetOfExactType<ReminderScope>();
    assert(scope != null, 'No ReminderScope found in the widget tree');
    return scope!.notifier!;
  }
}
