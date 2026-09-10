import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vocabulary.dart';

/// Die selbst gemerkten Karten.
///
/// Der eingebaute Inhalt liegt `const` im Code — gemerkte Funde können das
/// nicht. Sie brauchen deshalb einen eigenen Speicher, der beim Start
/// gelesen und in die Registry eingehängt wird.
class CustomCardStore extends ChangeNotifier {
  CustomCardStore({SharedPreferences? prefs}) : _prefs = prefs;

  /// Präfix wie bei allen anderen Schlüsseln — siehe `naming_test.dart`.
  /// Es bleibt „arabisch_lernen", auch wenn die App anders heißt.
  static const String storageKey = 'arabisch_lernen.cards.v1';

  SharedPreferences? _prefs;
  final List<VocabEntry> _cards = <VocabEntry>[];
  bool _loaded = false;

  /// Die gemerkten Karten, neueste zuerst.
  List<VocabEntry> get cards => List<VocabEntry>.unmodifiable(_cards);

  bool get isEmpty => _cards.isEmpty;
  int get length => _cards.length;
  bool get isLoaded => _loaded;

  bool contains(String id) => _cards.any((VocabEntry c) => c.id == id);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final SharedPreferences prefs = await _preferences();
    final String? raw = prefs.getString(storageKey);
    if (raw != null) {
      _cards
        ..clear()
        ..addAll(_decode(raw));
    }
    notifyListeners();
  }

  /// Legt eine Karte ab. Gibt `false` zurück, wenn sie schon da ist —
  /// derselbe Fund an zwei Tagen soll den Lernstand nicht doppelt führen.
  Future<bool> add(VocabEntry card) async {
    await load();
    if (contains(card.id)) return false;
    _cards.insert(0, card);
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> remove(String id) async {
    await load();
    final int before = _cards.length;
    _cards.removeWhere((VocabEntry c) => c.id == id);
    if (_cards.length == before) return;
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _cards.clear();
    notifyListeners();
    final SharedPreferences prefs = await _preferences();
    await prefs.remove(storageKey);
  }

  Future<SharedPreferences> _preferences() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> _save() async {
    final SharedPreferences prefs = await _preferences();
    await prefs.setString(
      storageKey,
      jsonEncode(<Object?>[for (final VocabEntry c in _cards) _toJson(c)]),
    );
  }

  static Map<String, Object?> _toJson(VocabEntry card) => <String, Object?>{
        'term': card.german,
        'answer': card.answer,
        if (card.question != null) 'question': card.question,
        if (card.distractors.isNotEmpty) 'distractors': card.distractors,
        if (card.explanation != null) 'explanation': card.explanation,
        if (card.source != null) 'source': card.source,
      };

  /// Liest, was lesbar ist. Ein kaputter Eintrag kostet diese eine Karte,
  /// nicht die ganze Sammlung.
  static List<VocabEntry> _decode(String raw) {
    try {
      final Object? json = jsonDecode(raw);
      if (json is! List) return const <VocabEntry>[];
      return <VocabEntry>[
        for (final Object? entry in json)
          if (_fromJson(entry) case final VocabEntry card) card,
      ];
    } catch (error) {
      debugPrint('Gemerkte Karten unlesbar: $error');
      return const <VocabEntry>[];
    }
  }

  static VocabEntry? _fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? term = json['term'];
    final Object? answer = json['answer'];
    if (term is! String || answer is! String) return null;
    if (term.trim().isEmpty || answer.trim().isEmpty) return null;
    final Object? question = json['question'];
    final Object? distractors = json['distractors'];
    return VocabEntry(
      term,
      answer,
      '',
      question: question is String ? question : null,
      distractors: distractors is List
          ? <String>[
              for (final Object? d in distractors)
                if (d is String) d,
            ]
          : const <String>[],
      explanation: json['explanation'] is String
          ? json['explanation'] as String
          : null,
      source: json['source'] is String ? json['source'] as String : null,
      script: TextScript.latin,
    );
  }
}

/// Macht die gemerkten Karten im Baum verfügbar.
class CustomCardScope extends InheritedNotifier<CustomCardStore> {
  const CustomCardScope({
    super.key,
    required CustomCardStore store,
    required super.child,
  }) : super(notifier: store);

  static CustomCardStore of(BuildContext context) {
    final CustomCardScope? scope =
        context.dependOnInheritedWidgetOfExactType<CustomCardScope>();
    assert(scope != null, 'Kein CustomCardScope im Baum');
    return scope!.notifier!;
  }
}
