import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/vocabulary_data.dart';
import '../models/vocabulary.dart';
import 'progress_store.dart';
import 'word_progress.dart';

/// Tracks what the learner knows, when each word is due again, and how the
/// last days went. Everything is written to the device through
/// [ProgressStore], so closing the app no longer loses the progress.
class LearningState extends ChangeNotifier {
  LearningState({ProgressStore? store, DateTime Function()? clock})
      : _store = store ?? ProgressStore(),
        _now = clock ?? DateTime.now;

  final ProgressStore _store;
  final DateTime Function() _now;

  final Map<String, WordProgress> _words = <String, WordProgress>{};
  Map<String, int> _history = <String, int>{};

  bool _loaded = false;
  int _answered = 0;
  int _correct = 0;
  int _sessionStreak = 0;
  int _bestStreak = 0;
  int _dailyGoal = 10;

  bool get isLoaded => _loaded;
  int get answered => _answered;
  int get correct => _correct;

  /// Correct answers in a row within this session.
  int get streak => _sessionStreak;
  int get bestStreak => _bestStreak;

  int get dailyGoal => _dailyGoal;
  int get totalCount => kAllEntries.length;

  static const int maxBox = WordProgress.maxBox;

  /// Loads the stored progress. Safe to call more than once.
  Future<void> load() async {
    final StoredProgress stored = await _store.load();
    _words
      ..clear()
      ..addAll(stored.words);
    _history = Map<String, int>.of(stored.history);
    _answered = stored.answered;
    _correct = stored.correct;
    _bestStreak = stored.bestStreak;
    _dailyGoal = stored.dailyGoal;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _store.save(StoredProgress(
        words: _words,
        answered: _answered,
        correct: _correct,
        bestStreak: _bestStreak,
        dailyGoal: _dailyGoal,
        history: _history,
      ));

  WordProgress progressOfWord(VocabEntry entry) =>
      _words[entry.id] ?? WordProgress();

  int boxOf(VocabEntry entry) => progressOfWord(entry).box;

  bool isLearned(VocabEntry entry) => progressOfWord(entry).isLearned;

  bool isDue(VocabEntry entry) => progressOfWord(entry).isDue(_now());

  DateTime? dueDateOf(VocabEntry entry) => progressOfWord(entry).due;

  int get learnedCount =>
      _words.values.where((WordProgress w) => w.isLearned).length;

  int get startedCount => _words.values
      .where((WordProgress w) => w.box > 0 && !w.isLearned)
      .length;

  double get overallProgress =>
      totalCount == 0 ? 0 : learnedCount / totalCount;

  /// Words waiting for a repetition today — the heart of the daily routine.
  List<VocabEntry> dueEntries([List<VocabEntry>? pool]) {
    final DateTime now = _now();
    return <VocabEntry>[
      for (final VocabEntry entry in pool ?? kAllEntries)
        if (progressOfWord(entry).isDue(now)) entry,
    ];
  }

  int get dueCount => dueEntries().length;

  /// Answers given today, and whether the daily goal is reached.
  int get answeredToday => _history[dayKey(_now())] ?? 0;

  bool get goalReached => answeredToday >= _dailyGoal;

  double get goalProgress =>
      _dailyGoal == 0 ? 1 : min(1, answeredToday / _dailyGoal);

  /// Consecutive days up to today in which the daily goal was reached.
  int get dayStreak {
    int streak = 0;
    DateTime day = dayOf(_now());
    // Today only breaks the streak once it is over, so a day that has not
    // reached the goal yet is simply skipped.
    if ((_history[dayKey(day)] ?? 0) < _dailyGoal) {
      day = day.subtract(const Duration(days: 1));
    }
    while ((_history[dayKey(day)] ?? 0) >= _dailyGoal) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Answers per day for the last [days] days, oldest first.
  List<MapEntry<DateTime, int>> recentActivity({int days = 14}) {
    final DateTime today = dayOf(_now());
    return <MapEntry<DateTime, int>>[
      for (int i = days - 1; i >= 0; i--)
        () {
          final DateTime day = today.subtract(Duration(days: i));
          return MapEntry<DateTime, int>(day, _history[dayKey(day)] ?? 0);
        }(),
    ];
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal.clamp(1, 200);
    notifyListeners();
    await _persist();
  }

  void _update(VocabEntry entry, WordProgress next, {bool persist = true}) {
    _words[entry.id] = next;
    notifyListeners();
    if (persist) unawaited(_persist());
  }

  /// A correct answer: one box up, next repetition further away.
  void promote(VocabEntry entry) =>
      _update(entry, progressOfWord(entry).promote(_now()));

  /// A wrong answer: back to the first box, due again today.
  void demote(VocabEntry entry) =>
      _update(entry, progressOfWord(entry).demote(_now()));

  void markLearned(VocabEntry entry) => _update(
      entry, progressOfWord(entry).setBox(WordProgress.maxBox, _now()));

  void markUnlearned(VocabEntry entry) =>
      _update(entry, progressOfWord(entry).setBox(0, _now()));

  void toggleLearned(VocabEntry entry) {
    if (isLearned(entry)) {
      markUnlearned(entry);
    } else {
      markLearned(entry);
    }
  }

  int learnedIn(VocabCategory category) =>
      category.entries.where(isLearned).length;

  double progressOf(VocabCategory category) => category.entries.isEmpty
      ? 0
      : learnedIn(category) / category.entries.length;

  int dueIn(VocabCategory category) => dueEntries(category.entries).length;

  /// Training order: what is due comes first, then the weakest boxes,
  /// shuffled inside a group so a round never feels the same twice.
  List<VocabEntry> trainingOrder(List<VocabEntry> pool, {Random? random}) {
    final DateTime now = _now();
    final Random rnd = random ?? Random();
    final List<VocabEntry> shuffled = List<VocabEntry>.of(pool)..shuffle(rnd);
    shuffled.sort((VocabEntry a, VocabEntry b) {
      final WordProgress pa = progressOfWord(a);
      final WordProgress pb = progressOfWord(b);
      final int dueOrder = (pb.isDue(now) ? 1 : 0) - (pa.isDue(now) ? 1 : 0);
      if (dueOrder != 0) return dueOrder;
      return pa.box.compareTo(pb.box);
    });
    return shuffled;
  }

  void recordAnswer({required bool correct}) {
    _answered++;
    if (correct) {
      _correct++;
      _sessionStreak++;
      _bestStreak = max(_bestStreak, _sessionStreak);
    } else {
      _sessionStreak = 0;
    }
    final String key = dayKey(_now());
    _history[key] = (_history[key] ?? 0) + 1;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> reset() async {
    _words.clear();
    _history = <String, int>{};
    _answered = 0;
    _correct = 0;
    _sessionStreak = 0;
    _bestStreak = 0;
    notifyListeners();
    await _store.clear();
  }
}

/// Makes the [LearningState] available to the whole widget tree.
class LearningScope extends InheritedNotifier<LearningState> {
  const LearningScope({
    super.key,
    required LearningState state,
    required super.child,
  }) : super(notifier: state);

  static LearningState of(BuildContext context) {
    final LearningScope? scope =
        context.dependOnInheritedWidgetOfExactType<LearningScope>();
    assert(scope != null, 'No LearningScope found in the widget tree');
    return scope!.notifier!;
  }
}
