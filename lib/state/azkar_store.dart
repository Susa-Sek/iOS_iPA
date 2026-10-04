import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/azkar.dart';
import 'word_progress.dart';

/// Was heute schon gesprochen ist, und wie viele Tage am Stück.
///
/// **Eine eigene Spur, getrennt vom Lernen.** Kein XP, kein Level, keine
/// Lern-Abzeichen, kein Einfluss auf den Jokertag: Die Azkar berühren den
/// Lernstand an keiner Stelle. Gottesdienst gegen Punkte zu tauschen wäre
/// schief — eine eigene, ruhige Serie genügt.
///
/// Gespeichert wird nur, **was heute zählt**, plus die Serie. Der Zähler je
/// Dhikr rollt um Mitternacht mit dem Tag um, wie beim [RewardStore].
class AzkarStore extends ChangeNotifier {
  AzkarStore({SharedPreferences? preferences, DateTime Function()? clock})
      : _prefs = preferences,
        _now = clock ?? DateTime.now;

  /// Nicht umbenennen — siehe test/naming_test.dart.
  static const String storageKey = 'arabisch_lernen.azkar.v1';

  SharedPreferences? _prefs;
  final DateTime Function() _now;

  String _tag = '';

  /// Wie oft ein Dhikr heute schon gesprochen wurde, je Hälfte.
  final Map<String, int> _heute = <String, int>{};

  /// Die zuletzt abgeschlossenen Tage je Hälfte, als "YYYY-MM-DD".
  final Map<AzkarTime, String> _zuletzt = <AzkarTime, String>{};

  /// Die laufende Serie je Hälfte.
  final Map<AzkarTime, int> _serie = <AzkarTime, int>{};

  bool _geladen = false;
  bool get isLoaded => _geladen;

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final String? roh = _prefs?.getString(storageKey);
      if (roh != null && roh.isNotEmpty) _lies(roh);
    } catch (error) {
      debugPrint('Azkar-Stand nicht lesbar: $error');
    }
    _geladen = true;
    _rollOver();
    notifyListeners();
  }

  void _lies(String roh) {
    final Object? json = jsonDecode(roh);
    if (json is! Map) return;
    _tag = (json['tag'] as String?) ?? '';
    final Object? heute = json['heute'];
    if (heute is Map) {
      for (final MapEntry<Object?, Object?> e in heute.entries) {
        if (e.key is String && e.value is num) {
          _heute[e.key! as String] = (e.value! as num).toInt();
        }
      }
    }
    for (final AzkarTime t in AzkarTime.values) {
      final Object? z = json['zuletzt_${t.id}'];
      if (z is String && z.isNotEmpty) _zuletzt[t] = z;
      final Object? s = json['serie_${t.id}'];
      if (s is num) _serie[t] = s.toInt();
    }
  }

  /// Ein neuer Tag räumt die Zähler ab — die Serie bleibt.
  void _rollOver() {
    final String jetzt = dayKey(_now());
    if (_tag == jetzt) return;
    _tag = jetzt;
    _heute.clear();
  }

  String _schluessel(AzkarTime time, String dhikrId) => '${time.id}/$dhikrId';

  /// Wie oft dieses Dhikr heute schon gesprochen wurde.
  int zaehler(AzkarTime time, Dhikr dhikr) {
    _rollOver();
    return _heute[_schluessel(time, dhikr.id)] ?? 0;
  }

  bool istFertig(AzkarTime time, Dhikr dhikr) =>
      zaehler(time, dhikr) >= dhikr.count;

  /// Einmal gesprochen — der Zähler geht eins hoch.
  Future<void> tippe(AzkarTime time, Dhikr dhikr, List<Dhikr> pensum) async {
    _rollOver();
    final String k = _schluessel(time, dhikr.id);
    final int neu = (_heute[k] ?? 0) + 1;
    _heute[k] = neu > dhikr.count ? dhikr.count : neu;
    _pruefeAbschluss(time, pensum);
    notifyListeners();
    await _schreibe();
  }

  /// Ein Dhikr wieder öffnen — wer sich vertippt, soll zurückkönnen.
  Future<void> zuruecksetzen(AzkarTime time, Dhikr dhikr) async {
    _rollOver();
    _heute.remove(_schluessel(time, dhikr.id));
    notifyListeners();
    await _schreibe();
  }

  /// Ist das Pensum dieser Hälfte heute vollständig?
  bool istHaelfteFertig(AzkarTime time, List<Dhikr> pensum) {
    if (pensum.isEmpty) return false;
    return pensum.every((Dhikr d) => istFertig(time, d));
  }

  /// Wie viele der Hälfte heute stehen.
  int fertigeVon(AzkarTime time, List<Dhikr> pensum) =>
      pensum.where((Dhikr d) => istFertig(time, d)).length;

  void _pruefeAbschluss(AzkarTime time, List<Dhikr> pensum) {
    if (!istHaelfteFertig(time, pensum)) return;
    final String heute = dayKey(_now());
    if (_zuletzt[time] == heute) return;

    final String? vorher = _zuletzt[time];
    final String gestern =
        dayKey(dayOf(_now()).subtract(const Duration(days: 1)));
    // Direkt angeschlossen heißt weiterzählen, sonst beginnt die Serie neu.
    _serie[time] = vorher == gestern ? (_serie[time] ?? 0) + 1 : 1;
    _zuletzt[time] = heute;
  }

  /// Tage am Stück für diese Hälfte.
  ///
  /// Eine Serie, die gestern endete, läuft heute noch — sie reißt erst, wenn
  /// ein ganzer Tag dazwischen liegt. Sonst stünde den halben Tag über eine
  /// Null da, obwohl nichts verloren ist.
  int serie(AzkarTime time) {
    final String? zuletzt = _zuletzt[time];
    if (zuletzt == null) return 0;
    final DateTime heute = dayOf(_now());
    final String gestern =
        dayKey(heute.subtract(const Duration(days: 1)));
    if (zuletzt != dayKey(heute) && zuletzt != gestern) return 0;
    return _serie[time] ?? 0;
  }

  bool heuteSchonFertig(AzkarTime time) => _zuletzt[time] == dayKey(_now());

  Future<void> _schreibe() async {
    try {
      await _prefs?.setString(
        storageKey,
        jsonEncode(<String, dynamic>{
          'tag': _tag,
          'heute': _heute,
          for (final AzkarTime t in AzkarTime.values) ...<String, dynamic>{
            if (_zuletzt[t] case final String z) 'zuletzt_${t.id}': z,
            'serie_${t.id}': _serie[t] ?? 0,
          },
        }),
      );
    } catch (error) {
      debugPrint('Azkar-Stand nicht speicherbar: $error');
    }
  }

  /// Nur für „Fortschritt zurücksetzen".
  Future<void> reset() async {
    _heute.clear();
    _zuletzt.clear();
    _serie.clear();
    notifyListeners();
    await _schreibe();
  }
}

/// Macht den Azkar-Stand im Baum verfügbar.
class AzkarScope extends InheritedNotifier<AzkarStore> {
  const AzkarScope({
    super.key,
    required AzkarStore store,
    required super.child,
  }) : super(notifier: store);

  static AzkarStore of(BuildContext context) {
    final AzkarScope? scope =
        context.dependOnInheritedWidgetOfExactType<AzkarScope>();
    assert(scope != null, 'No AzkarScope found in the widget tree');
    return scope!.notifier!;
  }
}
