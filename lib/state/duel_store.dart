import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'duel.dart';

/// Ein gespieltes Duell mit dem, was man davon weiß.
@immutable
class DuelRecord {
  const DuelRecord({
    required this.code,
    required this.topicId,
    required this.duelId,
    required this.own,
    required this.total,
    this.theirs,
    this.startedByMe = true,
  });

  /// Der Code, wie er verschickt wurde — man kann ihn noch einmal senden.
  final String code;
  final String topicId;
  final int duelId;

  /// Das eigene Ergebnis.
  final int own;
  final int total;

  /// Das Ergebnis des anderen, sobald sein Code eingetragen wurde.
  final int? theirs;

  final bool startedByMe;

  bool get complete => theirs != null;

  /// `true` gewonnen, `false` verloren, `null` unentschieden oder offen.
  bool? get won {
    final int? andere = theirs;
    if (andere == null || andere == own) return null;
    return own > andere;
  }

  DuelRecord withTheirs(int ergebnis) => DuelRecord(
        code: code,
        topicId: topicId,
        duelId: duelId,
        own: own,
        total: total,
        theirs: ergebnis,
        startedByMe: startedByMe,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'code': code,
        'topic': topicId,
        'id': duelId,
        'own': own,
        'total': total,
        if (theirs != null) 'theirs': theirs,
        'mine': startedByMe,
      };

  static DuelRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? code = json['code'];
    final Object? id = json['id'];
    final Object? own = json['own'];
    final Object? total = json['total'];
    if (code is! String || id is! num || own is! num || total is! num) {
      return null;
    }
    return DuelRecord(
      code: code,
      topicId: json['topic'] is String ? json['topic'] as String : '',
      duelId: id.toInt(),
      own: own.toInt(),
      total: total.toInt(),
      theirs: json['theirs'] is num ? (json['theirs'] as num).toInt() : null,
      startedByMe: json['mine'] != false,
    );
  }
}

/// Die Duelle, die man gespielt hat.
///
/// Ohne Server gibt es keine Liste, die irgendwo läge — sie liegt hier, auf
/// dem Gerät, und ist der einzige Grund, warum ein zurückgeschickter
/// Ergebnis-Code überhaupt zugeordnet werden kann.
class DuelStore extends ChangeNotifier {
  /// Präfix wie bei allen anderen Schlüsseln — siehe `naming_test.dart`.
  static const String storageKey = 'arabisch_lernen.duels.v1';

  /// Wie viele Duelle aufgehoben werden. Mehr braucht niemand, und der
  /// Speicher soll nicht endlos wachsen.
  static const int maxRecords = 30;

  final List<DuelRecord> _duelle = <DuelRecord>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Neueste zuerst.
  List<DuelRecord> get records => List<DuelRecord>.unmodifiable(_duelle);

  List<DuelRecord> get open =>
      <DuelRecord>[for (final DuelRecord d in _duelle) if (!d.complete) d];

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(storageKey);
    if (raw != null) _decode(raw);
    notifyListeners();
  }

  Future<void> add(DuelRecord record) async {
    await load();
    _duelle
      ..removeWhere((DuelRecord d) => d.duelId == record.duelId)
      ..insert(0, record);
    if (_duelle.length > maxRecords) _duelle.removeRange(maxRecords, _duelle.length);
    notifyListeners();
    await _save();
  }

  /// Trägt das Ergebnis des anderen ein.
  ///
  /// Gibt zurück, zu welchem Duell es gehörte — oder `null`, wenn kein
  /// passendes da ist. Das ist der Fall, den der Bildschirm erklären muss:
  /// „Zu diesem Code gibt es hier kein Duell."
  Future<DuelRecord?> applyResult(DuelResult result) async {
    await load();
    final int i =
        _duelle.indexWhere((DuelRecord d) => d.duelId == result.duelId);
    if (i < 0) return null;
    _duelle[i] = _duelle[i].withTheirs(result.correct);
    notifyListeners();
    await _save();
    return _duelle[i];
  }

  Future<void> reset() async {
    _duelle.clear();
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<void> _save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(<Object?>[for (final DuelRecord d in _duelle) d.toJson()]),
    );
  }

  void _decode(String raw) {
    try {
      final Object? json = jsonDecode(raw);
      if (json is! List) return;
      for (final Object? eintrag in json) {
        final DuelRecord? record = DuelRecord.fromJson(eintrag);
        if (record != null) _duelle.add(record);
      }
    } catch (error) {
      debugPrint('Duelle unlesbar: $error');
    }
  }
}

/// Macht die Duelle im Baum verfügbar.
class DuelScope extends InheritedNotifier<DuelStore> {
  const DuelScope({
    super.key,
    required DuelStore store,
    required super.child,
  }) : super(notifier: store);

  static DuelStore of(BuildContext context) {
    final DuelScope? scope =
        context.dependOnInheritedWidgetOfExactType<DuelScope>();
    assert(scope != null, 'Kein DuelScope im Baum');
    return scope!.notifier!;
  }
}
