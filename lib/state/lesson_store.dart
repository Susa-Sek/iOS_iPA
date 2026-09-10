import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/knowledge/lessons.dart';
import '../models/vocabulary.dart';

/// Was von den Lektionen schon durchgearbeitet ist.
///
/// Ein eigener Speicher neben dem Lernstand, nicht statt seiner: Die Fragen
/// behalten ihre Leitner-Fächer, hier steht nur, welche **Lektion** wann
/// abgeschlossen wurde. Im Wissen ist das Maß nicht die abgehakte Karte,
/// sondern das durchgearbeitete Thema.
class LessonStore extends ChangeNotifier {
  LessonStore({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  /// Präfix wie bei allen anderen Schlüsseln — siehe `naming_test.dart`.
  static const String storageKey = 'arabisch_lernen.lessons.v1';

  final DateTime Function() _now;
  final Map<String, DateTime> _erledigt = <String, DateTime>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Wie oft eine Lektion abgeschlossen wurde, ist egal — nur ob.
  bool isDone(String lessonId) => _erledigt.containsKey(lessonId);

  DateTime? doneAt(String lessonId) => _erledigt[lessonId];

  int get doneCount => _erledigt.length;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(storageKey);
    if (raw != null) _erledigt.addAll(_decode(raw));
    notifyListeners();
  }

  Future<void> markDone(String lessonId) async {
    await load();
    _erledigt[lessonId] = _now();
    notifyListeners();
    await _save();
  }

  Future<void> reset() async {
    _erledigt.clear();
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  // ---- Fortschritt ------------------------------------------------------

  List<KnowledgeLesson> lessonsIn(VocabCategory category) =>
      lessonsOf(category);

  int doneIn(VocabCategory category) =>
      lessonsOf(category).where((KnowledgeLesson l) => isDone(l.id)).length;

  /// Ein Thema gilt als verstanden, wenn beide Lektionen durch sind.
  bool isUnderstood(VocabCategory category) {
    final List<KnowledgeLesson> lektionen = lessonsOf(category);
    return lektionen.isNotEmpty && lektionen.every((l) => isDone(l.id));
  }

  int understoodIn(Iterable<VocabCategory> categories) =>
      categories.where(isUnderstood).length;

  double progressIn(VocabCategory category) {
    final int gesamt = lessonsOf(category).length;
    return gesamt == 0 ? 0 : doneIn(category) / gesamt;
  }

  /// Die Lektion, die als Nächstes dran ist.
  ///
  /// Erst die nächste offene in der Reihenfolge der Themen — man soll ein
  /// Thema zu Ende bringen können. Ist alles durch, die am längsten
  /// zurückliegende: So wird eine abgeschlossene App nicht zur Sackgasse.
  KnowledgeLesson? nextLesson([List<KnowledgeLesson>? pool]) {
    final List<KnowledgeLesson> alle = pool ?? kLessons;
    if (alle.isEmpty) return null;

    for (final KnowledgeLesson lesson in alle) {
      if (!isDone(lesson.id)) return lesson;
    }

    KnowledgeLesson aelteste = alle.first;
    for (final KnowledgeLesson lesson in alle) {
      final DateTime? a = doneAt(lesson.id);
      final DateTime? b = doneAt(aelteste.id);
      if (a == null) return lesson;
      if (b == null || a.isBefore(b)) aelteste = lesson;
    }
    return aelteste;
  }

  // ---- Speicher ---------------------------------------------------------

  Future<void> _save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(<String, String>{
        for (final MapEntry<String, DateTime> e in _erledigt.entries)
          e.key: e.value.toIso8601String(),
      }),
    );
  }

  /// Liest, was lesbar ist. Ein kaputter Eintrag kostet diese eine Lektion,
  /// nicht den ganzen Fortschritt.
  static Map<String, DateTime> _decode(String raw) {
    try {
      final Object? json = jsonDecode(raw);
      if (json is! Map) return <String, DateTime>{};
      final Map<String, DateTime> out = <String, DateTime>{};
      for (final MapEntry<Object?, Object?> e in json.entries) {
        final Object? key = e.key;
        final Object? value = e.value;
        if (key is! String || value is! String) continue;
        final DateTime? wann = DateTime.tryParse(value);
        if (wann != null) out[key] = wann;
      }
      return out;
    } catch (error) {
      debugPrint('Lektionsfortschritt unlesbar: $error');
      return <String, DateTime>{};
    }
  }
}

/// Macht den Lektionsfortschritt im Baum verfügbar.
class LessonScope extends InheritedNotifier<LessonStore> {
  const LessonScope({
    super.key,
    required LessonStore store,
    required super.child,
  }) : super(notifier: store);

  static LessonStore of(BuildContext context) {
    final LessonScope? scope =
        context.dependOnInheritedWidgetOfExactType<LessonScope>();
    assert(scope != null, 'Kein LessonScope im Baum');
    return scope!.notifier!;
  }
}
