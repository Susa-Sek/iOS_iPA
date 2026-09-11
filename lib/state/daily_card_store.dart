import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vocabulary.dart';
import 'card_codec.dart';

/// Die Karten, die der Tagesstoff von selbst gebracht hat.
///
/// **Warum nicht in `CustomCardStore`.** „Gemerkt" heißt: *das habe ich mir
/// aufgehoben.* Automatisch Eingesammeltes dort hineinzumischen hieße, dass
/// ein „Alles löschen" beides trifft und niemand die beiden auseinanderhalten
/// kann. Zwei Speicher, zwei Themen, zwei Knöpfe.
class DailyCardStore extends ChangeNotifier {
  DailyCardStore({SharedPreferences? prefs}) : _prefs = prefs;

  /// Präfix wie bei allen anderen Schlüsseln — siehe `naming_test.dart`.
  static const String storageKey = 'arabisch_lernen.daily_cards.v1';

  /// Wie viele Karten aufgehoben werden — rund drei Monate bei zwei am Tag.
  ///
  /// Ohne Grenze wüchse der Bestand um 730 Karten im Jahr, und die
  /// Wiederholung bestünde irgendwann nur noch aus Tagestrivia.
  static const int maxCards = 180;

  SharedPreferences? _prefs;
  final List<VocabEntry> _cards = <VocabEntry>[];
  bool _enabled = true;
  bool _loaded = false;

  /// Neueste zuerst.
  List<VocabEntry> get cards => List<VocabEntry>.unmodifiable(_cards);

  /// Die Karten des jüngsten Fundes — das, was „neu von heute" meint.
  List<VocabEntry> get latest =>
      List<VocabEntry>.unmodifiable(_cards.take(_letzteErnte));
  int _letzteErnte = 0;

  bool get isEmpty => _cards.isEmpty;
  int get length => _cards.length;
  bool get isLoaded => _loaded;

  /// Ob überhaupt geerntet wird. Aus heißt: Der Bestand bleibt liegen, es
  /// kommt nur nichts dazu.
  bool get enabled => _enabled;

  bool contains(String id) => _cards.any((VocabEntry c) => c.id == id);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final SharedPreferences prefs = await _preferences();
    final String? raw = prefs.getString(storageKey);
    if (raw != null) _decode(raw);
    notifyListeners();
  }

  Future<void> setEnabled(bool on) async {
    await load();
    if (_enabled == on) return;
    _enabled = on;
    notifyListeners();
    await _save();
  }

  /// Legt die Karten eines Tages ab.
  ///
  /// Gibt die **Kennungen der weggefallenen** Karten zurück, nicht nur eine
  /// Zahl: Der Lernkern muss ihre Lernstufen mit wegwerfen, sonst wächst der
  /// Lernstand still weiter mit Einträgen zu Karten, die es nicht mehr gibt.
  Future<List<String>> addAll(List<VocabEntry> neue) async {
    await load();
    if (!_enabled) return const <String>[];

    // Derselbe Fund an zwei Tagen darf den Lernstand nicht doppelt führen —
    // die id ist dessen Schlüssel.
    final List<VocabEntry> frisch = <VocabEntry>[
      for (final VocabEntry karte in neue)
        if (!contains(karte.id)) karte,
    ];
    _letzteErnte = frisch.length;
    if (frisch.isEmpty) return const <String>[];

    _cards.insertAll(0, frisch);

    final List<String> weg = <String>[];
    while (_cards.length > maxCards) {
      weg.add(_cards.removeLast().id);
    }

    notifyListeners();
    await _save();
    return weg;
  }

  Future<void> remove(String id) async {
    await load();
    final int vorher = _cards.length;
    _cards.removeWhere((VocabEntry c) => c.id == id);
    if (_cards.length == vorher) return;
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _cards.clear();
    _letzteErnte = 0;
    notifyListeners();
    await _save();
  }

  Future<SharedPreferences> _preferences() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> _save() async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setString(
      storageKey,
      jsonEncode(<String, Object?>{
        'enabled': _enabled,
        'cards': <Object?>[
          for (final VocabEntry c in _cards) CardCodec.toJson(c),
        ],
      }),
    );
  }

  /// Liest, was lesbar ist. Ein kaputter Eintrag kostet diese eine Karte,
  /// nicht die Sammlung — und eine kaputte Sammlung nicht den Lernstand, der
  /// woanders liegt.
  void _decode(String raw) {
    try {
      final Object? json = jsonDecode(raw);
      if (json is! Map) return;
      _enabled = json['enabled'] != false;
      final Object? cards = json['cards'];
      if (cards is! List) return;
      for (final Object? eintrag in cards) {
        final VocabEntry? karte = CardCodec.fromJson(eintrag);
        if (karte != null && !contains(karte.id)) _cards.add(karte);
      }
    } catch (error) {
      debugPrint('Tagesfunde unlesbar: $error');
    }
  }
}

/// Macht die Tagesfunde im Baum verfügbar.
class DailyCardScope extends InheritedNotifier<DailyCardStore> {
  const DailyCardScope({
    super.key,
    required DailyCardStore store,
    required super.child,
  }) : super(notifier: store);

  static DailyCardStore of(BuildContext context) {
    final DailyCardScope? scope =
        context.dependOnInheritedWidgetOfExactType<DailyCardScope>();
    assert(scope != null, 'Kein DailyCardScope im Baum');
    return scope!.notifier!;
  }
}
