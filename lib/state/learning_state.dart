import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/achievements_data.dart';
import '../data/content_registry.dart';
import '../models/achievement.dart';
import '../models/vocabulary.dart';
import 'progress_store.dart';
import 'word_progress.dart';

/// Tracks what the learner knows, when each word is due again, and how the
/// last days went. Everything is written to the device through
/// [ProgressStore], so closing the app no longer loses the progress.
class LearningState extends ChangeNotifier {
  LearningState({
    ProgressStore? store,
    DateTime Function()? clock,
    ContentRegistry? content,
  })  : _store = store ?? ProgressStore(),
        _now = clock ?? DateTime.now,
        _content = content ?? kDefaultContent;

  final ProgressStore _store;
  final DateTime Function() _now;

  /// Woher die Inhalte kommen. Der Lernkern kennt keine einzelne Sprache
  /// mehr, nur noch diese Registry.
  final ContentRegistry _content;

  ContentRegistry get content => _content;

  /// Der Inhalt hat sich geändert — etwa weil eine Karte gemerkt wurde.
  ///
  /// Die Registry liest die gemerkten Karten bei jedem Zugriff neu; ohne
  /// diesen Anstoß würde die Startseite die neue Karte aber erst beim
  /// nächsten Start zeigen.
  void contentChanged() => notifyListeners();

  final Map<String, WordProgress> _words = <String, WordProgress>{};
  Map<String, int> _history = <String, int>{};

  bool _loaded = false;
  int _answered = 0;
  int _correct = 0;
  int _sessionStreak = 0;
  int _bestStreak = 0;
  int _dailyGoal = 10;
  int _xp = 0;
  int _perfectRounds = 0;
  int _goalDays = 0;

  bool get isLoaded => _loaded;
  int get answered => _answered;
  int get correct => _correct;

  /// Correct answers in a row within this session.
  int get streak => _sessionStreak;
  int get bestStreak => _bestStreak;

  int get dailyGoal => _dailyGoal;
  int get totalCount => _content.entries.length;

  // ---- Punkte und Level -------------------------------------------------

  /// Punkte je Antwort und für ein erreichtes Tagesziel.
  static const int xpPerCorrect = 10;
  static const int xpPerWrong = 2;
  static const int xpPerGoal = 50;

  int get xp => _xp;
  int get perfectRounds => _perfectRounds;
  int get goalDays => _goalDays;

  /// Level 1 ab 0 Punkten, danach quadratisch steigender Bedarf: Level 2 ab
  /// 100, Level 3 ab 400, Level 4 ab 900 Punkten.
  int get level => 1 + (sqrt(_xp / 100)).floor();

  int get xpForCurrentLevel => _xpForLevel(level);
  int get xpForNextLevel => _xpForLevel(level + 1);

  static int _xpForLevel(int level) => 100 * (level - 1) * (level - 1);

  /// Fortschritt innerhalb des aktuellen Levels, 0 bis 1.
  double get levelProgress {
    final int span = xpForNextLevel - xpForCurrentLevel;
    if (span <= 0) return 1;
    return ((_xp - xpForCurrentLevel) / span).clamp(0, 1).toDouble();
  }

  /// Eine Runde ohne Fehler — zählt für das Abzeichen "Fehlerfrei".
  void recordPerfectRound() {
    _perfectRounds++;
    _xp += 25;
    notifyListeners();
    unawaited(_persist());
  }

  // ---- Abzeichen --------------------------------------------------------

  AchievementStats get achievementStats => AchievementStats(
        learnedWords: learnedCount,
        dayStreak: dayStreak,
        answers: _answered,
        perfectRounds: _perfectRounds,
        completedCategories: _content.categories
            .where((VocabCategory c) =>
                c.entries.isNotEmpty && c.entries.every(isLearned))
            .length,
        learnedQuranWords: _content
                .categoryById(AppContent.quranCategoryId)
                ?.entries
                .where(isLearned)
                .length ??
            0,
        level: level,
      );

  List<Achievement> get unlockedAchievements {
    final AchievementStats stats = achievementStats;
    return kAchievements
        .where((Achievement a) => a.isUnlocked(stats))
        .toList();
  }

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
    _xp = stored.xp;
    _perfectRounds = stored.perfectRounds;
    _goalDays = stored.goalDays;
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
        xp: _xp,
        perfectRounds: _perfectRounds,
        goalDays: _goalDays,
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
      for (final VocabEntry entry in pool ?? _content.entries)
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

  /// Gelernte Wörter eines Bereichs — die Startseite zeigt den Fortschritt
  /// bereichsweise statt als eine große Zahl über alles. Sonst fiele die
  /// Anzeige sichtbar ab, sobald ein neues Fach dazukommt, ohne dass jemand
  /// etwas verlernt hätte.
  int learnedInGroup(CategoryGroup group) =>
      group.entries.where(isLearned).length;

  double progressOfGroup(CategoryGroup group) {
    final int total = group.entries.length;
    return total == 0 ? 0 : learnedInGroup(group) / total;
  }

  int dueInGroup(CategoryGroup group) => dueEntries(group.entries).length;

  /// Wie viele Karten eine Tagesportion umfasst.
  ///
  /// Alle 1.100 Karten am Stück durchzugehen, schafft niemand — und wer es
  /// versucht, hört nach drei Tagen auf. Die Portion wächst mit dem
  /// Tagesziel: Wer sich mehr vornimmt, bekommt mehr.
  int get dosePerRound => (_dailyGoal * 2).clamp(10, 40);

  /// Die Karten für heute: fällige zuerst, dann die schwächsten — und nicht
  /// mehr, als in einer Sitzung zu schaffen ist.
  List<VocabEntry> dailySelection({
    List<VocabEntry>? pool,
    int? size,
    Random? random,
  }) {
    final List<VocabEntry> ordered =
        trainingOrder(pool ?? _content.entries, random: random);
    return ordered.take(min(size ?? dosePerRound, ordered.length)).toList();
  }

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
    final bool goalWasReached = goalReached;

    _answered++;
    _xp += correct ? xpPerCorrect : xpPerWrong;
    if (correct) {
      _correct++;
      _sessionStreak++;
      _bestStreak = max(_bestStreak, _sessionStreak);
    } else {
      _sessionStreak = 0;
    }
    final String key = dayKey(_now());
    _history[key] = (_history[key] ?? 0) + 1;

    // Der Moment, in dem das Tagesziel fällt: einmalig Punkte und ein Tag
    // mehr auf dem Konto.
    if (!goalWasReached && goalReached) {
      _xp += xpPerGoal;
      _goalDays++;
    }

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
    _xp = 0;
    _perfectRounds = 0;
    _goalDays = 0;
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
