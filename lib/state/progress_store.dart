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
  });

  final Map<String, WordProgress> words;
  final int answered;
  final int correct;
  final int bestStreak;

  /// How many answers count as one finished day.
  final int dailyGoal;

  /// Answers per day, keyed "YYYY-MM-DD".
  final Map<String, int> history;
}

/// Reads and writes [StoredProgress] — backed by shared_preferences, so the
/// learner keeps their boxes, streak and statistics when the app restarts.
class ProgressStore {
  ProgressStore({SharedPreferences? preferences}) : _prefs = preferences;

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

    return StoredProgress(
      answered: (decoded['answered'] as num?)?.toInt() ?? 0,
      correct: (decoded['correct'] as num?)?.toInt() ?? 0,
      bestStreak: (decoded['bestStreak'] as num?)?.toInt() ?? 0,
      dailyGoal: (decoded['dailyGoal'] as num?)?.toInt() ?? 10,
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
