import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'word_progress.dart';

/// Everything the app remembers between sessions.
@immutable
class StoredProgress {
  const StoredProgress({
    this.words = const <String, WordProgress>{},
    this.answered = 0,
    this.correct = 0,
    this.bestStreak = 0,
    this.dailyGoal = 10,
    this.history = const <String, int>{},
    this.xp = 0,
    this.perfectRounds = 0,
    this.goalDays = 0,
    this.freezes = 0,
    this.frozenDays = const <String>{},
    this.shortsDone = 0,
    this.questDays = 0,
    this.freezesEarned = 0,
  });

  final Map<String, WordProgress> words;
  final int answered;
  final int correct;
  final int bestStreak;

  /// How many answers count as one finished day.
  final int dailyGoal;

  /// Answers per day, keyed "YYYY-MM-DD".
  final Map<String, int> history;

  /// Erfahrungspunkte, Level werden daraus berechnet.
  final int xp;

  /// Quizrunden ohne einen Fehler.
  final int perfectRounds;

  /// Tage insgesamt, an denen das Tagesziel erreicht wurde.
  final int goalDays;

  /// Vorrätige Jokertage.
  ///
  /// Ein Jokertag hält die Serie über einen verpassten Tag hinweg. Ohne ihn
  /// löscht ein einziger kranker Tag eine Serie von dreißig — der häufigste
  /// Grund, ganz aufzuhören. Verdient wird er, nicht geschenkt: für einen
  /// Tag, an dem alle drei Tagesaufgaben erledigt sind.
  final int freezes;

  /// Tage, die ein Jokertag gerettet hat, als "YYYY-MM-DD".
  ///
  /// Sie werden festgehalten und nicht nur gezählt: Die Serie muss beim
  /// nächsten Start dieselbe sein, und es soll dabeistehen, welcher Tag
  /// gerettet wurde.
  final Set<String> frozenDays;

  /// Themen, die im Feed bis zum Ende durchgewischt wurden.
  final int shortsDone;

  /// Tage, an denen alle drei Tagesaufgaben erledigt waren.
  final int questDays;

  /// Wie viele Jokertage insgesamt verdient wurden — auch die schon
  /// verbrauchten. Der Vorrat allein taugt nicht als Maß: Wer seinen
  /// einzigen Joker eingesetzt hat, hat ihn trotzdem verdient.
  final int freezesEarned;
}

/// Reads and writes [StoredProgress] — backed by shared_preferences, so the
/// learner keeps their boxes, streak and statistics when the app restarts.
class ProgressStore {
  ProgressStore({SharedPreferences? preferences}) : _prefs = preferences;

  /// Heißt aus historischen Gründen "arabisch_lernen". Nicht umbenennen:
  /// Der Schlüssel ist der Lernstand bestehender Nutzer — ein neuer Name
  /// bedeutet, dass die App ihn nicht mehr findet. Abgesichert durch
  /// test/naming_test.dart.
  static const String storageKey = 'arabisch_lernen.progress.v1';

  /// Days of statistics kept — enough for the chart, small enough to stay fast.
  static const int historyDays = 120;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<StoredProgress> load() async {
    try {
      final SharedPreferences prefs = await _preferences;
      final String? raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return const StoredProgress();
      return decode(raw);
    } catch (error, stack) {
      // A damaged or unreadable store must never stop the app from starting.
      debugPrint('Lernstand konnte nicht geladen werden: $error\n$stack');
      return const StoredProgress();
    }
  }

  Future<bool> save(StoredProgress progress) async {
    try {
      final SharedPreferences prefs = await _preferences;
      return await prefs.setString(storageKey, encode(progress));
    } catch (error) {
      debugPrint('Lernstand konnte nicht gespeichert werden: $error');
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      final SharedPreferences prefs = await _preferences;
      return await prefs.remove(storageKey);
    } catch (error) {
      debugPrint('Lernstand konnte nicht gelöscht werden: $error');
      return false;
    }
  }

  @visibleForTesting
  static String encode(StoredProgress progress) {
    final Map<String, int> history = _trimHistory(progress.history);
    return jsonEncode(<String, dynamic>{
      'answered': progress.answered,
      'correct': progress.correct,
      'bestStreak': progress.bestStreak,
      'dailyGoal': progress.dailyGoal,
      'xp': progress.xp,
      'perfectRounds': progress.perfectRounds,
      'goalDays': progress.goalDays,
      'freezes': progress.freezes,
      'shortsDone': progress.shortsDone,
      'questDays': progress.questDays,
      'freezesEarned': progress.freezesEarned,
      'frozenDays': progress.frozenDays.toList()..sort(),
      'history': history,
      'words': <String, dynamic>{
        for (final MapEntry<String, WordProgress> e in progress.words.entries)
          e.key: e.value.toJson(),
      },
    });
  }

  @visibleForTesting
  static StoredProgress decode(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const StoredProgress();

    final Object? words = decoded['words'];
    final Object? history = decoded['history'];
    final Object? frozen = decoded['frozenDays'];

    return StoredProgress(
      answered: (decoded['answered'] as num?)?.toInt() ?? 0,
      correct: (decoded['correct'] as num?)?.toInt() ?? 0,
      bestStreak: (decoded['bestStreak'] as num?)?.toInt() ?? 0,
      dailyGoal: (decoded['dailyGoal'] as num?)?.toInt() ?? 10,
      xp: (decoded['xp'] as num?)?.toInt() ?? 0,
      perfectRounds: (decoded['perfectRounds'] as num?)?.toInt() ?? 0,
      goalDays: (decoded['goalDays'] as num?)?.toInt() ?? 0,
      // Fehlen die Felder, ist der Stand von vor dem Jokertag — er wird
      // gelesen wie bisher, nur ohne Joker.
      freezes: (decoded['freezes'] as num?)?.toInt() ?? 0,
      shortsDone: (decoded['shortsDone'] as num?)?.toInt() ?? 0,
      questDays: (decoded['questDays'] as num?)?.toInt() ?? 0,
      freezesEarned: (decoded['freezesEarned'] as num?)?.toInt() ?? 0,
      frozenDays: <String>{
        if (frozen is List)
          for (final Object? tag in frozen)
            if (tag is String) tag,
      },
      words: <String, WordProgress>{
        if (words is Map<String, dynamic>)
          for (final MapEntry<String, dynamic> e in words.entries)
            if (e.value is Map<String, dynamic>)
              e.key: WordProgress.fromJson(e.value as Map<String, dynamic>),
      },
      history: <String, int>{
        if (history is Map<String, dynamic>)
          for (final MapEntry<String, dynamic> e in history.entries)
            if (e.value is num) e.key: (e.value as num).toInt(),
      },
    );
  }

  /// Keeps the statistics from growing without bound.
  static Map<String, int> _trimHistory(Map<String, int> history) {
    if (history.length <= historyDays) return history;
    final List<String> keys = history.keys.toList()..sort();
    final List<String> keep = keys.sublist(keys.length - historyDays);
    return <String, int>{for (final String k in keep) k: history[k]!};
  }
}
