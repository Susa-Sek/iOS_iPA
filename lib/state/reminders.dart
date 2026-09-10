import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
  static const String hourKey = 'arabisch_lernen.reminder.hour';
  static const String minuteKey = 'arabisch_lernen.reminder.minute';

  /// How many days ahead are planned.
  static const int horizonDays = 14;

  final ReminderBackend _backend;
  final DateTime Function() _now;
  SharedPreferences? _prefs;

  bool _enabled = false;
  int _hour = 19;
  int _minute = 0;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  String get timeLabel =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('Erinnerungs-Einstellungen nicht lesbar: $error');
    }
    _enabled = _prefs?.getBool(enabledKey) ?? false;
    _hour = _prefs?.getInt(hourKey) ?? 19;
    _minute = _prefs?.getInt(minuteKey) ?? 0;
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

  /// Rebuilds the plan: cancel everything, then schedule the coming days.
  Future<void> refresh({required bool goalReachedToday, int? dueCount}) async {
    if (!_enabled) return;
    await _backend.cancelAll();
    for (final PlannedReminder reminder in plan(
      goalReachedToday: goalReachedToday,
      dueCount: dueCount,
    )) {
      await _backend.schedule(reminder);
    }
  }

  /// The reminders for the coming days — pure, so the tests can check it.
  @visibleForTesting
  List<PlannedReminder> plan({
    required bool goalReachedToday,
    int? dueCount,
  }) {
    final DateTime now = _now();
    final List<PlannedReminder> reminders = <PlannedReminder>[];

    for (int day = 0; day < horizonDays; day++) {
      final DateTime date = DateTime(now.year, now.month, now.day)
          .add(Duration(days: day));
      final DateTime when =
          DateTime(date.year, date.month, date.day, _hour, _minute);

      // Heute nur, wenn die Zeit noch kommt und das Ziel noch offen ist.
      if (day == 0 && (goalReachedToday || !when.isAfter(now))) continue;

      reminders.add(PlannedReminder(
        id: 1000 + day,
        when: when,
        title: day == 0 ? 'Deine Serie wartet' : 'Zeit für ein paar Wörter',
        body: day == 0 && dueCount != null && dueCount > 0
            ? '$dueCount ${dueCount == 1 ? "Wort ist" : "Wörter sind"} heute '
                'fällig — ein paar Minuten reichen.'
            : 'Ein paar Wörter heute halten die Serie am Leben.',
      ));
    }
    return reminders;
  }
}

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
