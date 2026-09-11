import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_quests.dart';
import 'word_progress.dart';

/// Was heute schon geschafft ist und welche Abzeichen schon gemeldet wurden.
///
/// Ein eigener Speicher neben dem Lernstand, aus demselben Grund wie der
/// `LessonStore`: Der Lernstand hält, was **gelernt** ist, und muss über
/// Jahre stabil bleiben. Hier steht, was **heute** läuft — und das ist
/// morgen wieder weg.
///
/// Die gemeldeten Abzeichen liegen mit hier, weil sie dieselbe Frage
/// beantworten: Was hat der Mensch schon gesehen?
class RewardStore extends ChangeNotifier {
  RewardStore({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  /// Präfix wie bei allen anderen Schlüsseln — siehe `naming_test.dart`.
  static const String storageKey = 'arabisch_lernen.rewards.v1';

  final DateTime Function() _now;

  String _tag = '';
  final Map<QuestKind, int> _stand = <QuestKind, int>{};
  bool _jokerHeute = false;
  final Set<String> _gemeldet = <String>{};

  bool _loaded = false;

  /// Ob hier noch nie etwas stand.
  ///
  /// Entscheidend beim ersten Start nach dem Update: Wer schon zwölf
  /// Abzeichen hat, soll nicht zwölf Meldungen hintereinander wegtippen
  /// müssen. Sie gelten dann als gesehen, ohne gezeigt zu werden.
  bool _frisch = false;

  bool get isLoaded => _loaded;
  bool get isFresh => _frisch;

  /// Wie weit eine Aufgabe heute ist.
  int progressOf(QuestKind kind) => _stand[kind] ?? 0;

  bool get freezeEarnedToday => _jokerHeute;

  bool wasAnnounced(String achievementId) => _gemeldet.contains(achievementId);

  /// Ob heute alle Aufgaben erledigt sind.
  bool allDone(List<Quest> quests) =>
      quests.isNotEmpty &&
      quests.every((Quest q) => q.isDone(progressOf(q.kind)));

  /// Wie viele davon erledigt sind.
  int doneCount(List<Quest> quests) =>
      quests.where((Quest q) => q.isDone(progressOf(q.kind))).length;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(storageKey);
    _frisch = raw == null;
    if (raw != null) _decode(raw);
    _rollOver();
    notifyListeners();
  }

  /// Zählt etwas mit, das gerade passiert ist.
  Future<void> report(QuestKind kind, {int amount = 1}) async {
    await load();
    _rollOver();
    _stand[kind] = (_stand[kind] ?? 0) + amount;
    notifyListeners();
    await _save();
  }

  /// Hält fest, dass der Jokertag für heute schon verdient wurde — damit er
  /// nicht bei jedem Neuzeichnen noch einmal vergeben wird.
  Future<void> markFreezeEarned() async {
    await load();
    _rollOver();
    if (_jokerHeute) return;
    _jokerHeute = true;
    notifyListeners();
    await _save();
  }

  /// Merkt sich, dass diese Abzeichen gezeigt wurden.
  Future<void> markAnnounced(Iterable<String> ids) async {
    await load();
    final int vorher = _gemeldet.length;
    _gemeldet.addAll(ids);
    if (_gemeldet.length == vorher) return;
    _frisch = false;
    notifyListeners();
    await _save();
  }

  Future<void> reset() async {
    _tag = '';
    _stand.clear();
    _jokerHeute = false;
    _gemeldet.clear();
    _frisch = true;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  // ---- Tageswechsel -----------------------------------------------------

  /// Ein neuer Tag löscht den Aufgabenstand. Die gemeldeten Abzeichen
  /// bleiben — die sind für immer gesehen.
  void _rollOver() {
    final String heute = dayKey(_now());
    if (_tag == heute) return;
    _tag = heute;
    _stand.clear();
    _jokerHeute = false;
  }

  // ---- Speicher ---------------------------------------------------------

  Future<void> _save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(<String, Object?>{
        'day': _tag,
        'quests': <String, int>{
          for (final MapEntry<QuestKind, int> e in _stand.entries)
            e.key.id: e.value,
        },
        'freezeEarned': _jokerHeute,
        'seen': _gemeldet.toList()..sort(),
      }),
    );
  }

  /// Liest, was lesbar ist. Ein kaputter Eintrag kostet den heutigen
  /// Aufgabenstand, nicht den Lernstand — der liegt woanders.
  void _decode(String raw) {
    try {
      final Object? json = jsonDecode(raw);
      if (json is! Map) return;
      _tag = json['day'] is String ? json['day'] as String : '';
      _jokerHeute = json['freezeEarned'] == true;

      final Object? quests = json['quests'];
      if (quests is Map) {
        for (final MapEntry<Object?, Object?> e in quests.entries) {
          final QuestKind? kind = QuestKind.byId(e.key as String?);
          final Object? wert = e.value;
          if (kind != null && wert is num) _stand[kind] = wert.toInt();
        }
      }

      final Object? seen = json['seen'];
      if (seen is List) {
        for (final Object? id in seen) {
          if (id is String) _gemeldet.add(id);
        }
      }
    } catch (error) {
      debugPrint('Tagesaufgaben unlesbar: $error');
    }
  }
}

/// Macht die Tagesaufgaben und die gemeldeten Abzeichen im Baum verfügbar.
class RewardScope extends InheritedNotifier<RewardStore> {
  const RewardScope({
    super.key,
    required RewardStore store,
    required super.child,
  }) : super(notifier: store);

  static RewardStore of(BuildContext context) {
    final RewardScope? scope =
        context.dependOnInheritedWidgetOfExactType<RewardScope>();
    assert(scope != null, 'Kein RewardScope im Baum');
    return scope!.notifier!;
  }

  /// Wie [of], aber ohne Bindung — für Meldungen aus Rückrufen heraus.
  static RewardStore? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<RewardScope>()
      ?.notifier;
}
