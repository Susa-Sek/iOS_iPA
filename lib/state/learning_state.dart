import 'dart:math';

import 'package:flutter/material.dart';

import '../data/vocabulary_data.dart';
import '../models/vocabulary.dart';

/// Tracks how well each word is known, using small Leitner boxes.
///
/// Every word sits in a box from 0 ("noch nie geübt") to [maxBox] ("sitzt").
/// A correct answer moves the word one box up, a wrong answer moves it back
/// to box 0, so the exercises keep returning to the words that are still
/// shaky. Everything lives in memory for the duration of the app session —
/// this project deliberately has no storage plugin.
class LearningState extends ChangeNotifier {
  static const int maxBox = 3;

  final Map<String, int> _boxes = <String, int>{};

  int _answered = 0;
  int _correct = 0;
  int _streak = 0;
  int _bestStreak = 0;

  int get answered => _answered;
  int get correct => _correct;
  int get streak => _streak;
  int get bestStreak => _bestStreak;

  int get totalCount => kAllEntries.length;

  int get learnedCount =>
      _boxes.values.where((int box) => box >= maxBox).length;

  int get startedCount =>
      _boxes.values.where((int box) => box > 0 && box < maxBox).length;

  double get overallProgress =>
      totalCount == 0 ? 0 : learnedCount / totalCount;

  int boxOf(VocabEntry entry) => _boxes[entry.id] ?? 0;

  bool isLearned(VocabEntry entry) => boxOf(entry) >= maxBox;

  /// A correct answer: one box up.
  void promote(VocabEntry entry) {
    _boxes[entry.id] = min(maxBox, boxOf(entry) + 1);
    notifyListeners();
  }

  /// A wrong answer: back to the start.
  void demote(VocabEntry entry) {
    _boxes[entry.id] = 0;
    notifyListeners();
  }

  void markLearned(VocabEntry entry) {
    _boxes[entry.id] = maxBox;
    notifyListeners();
  }

  void markUnlearned(VocabEntry entry) {
    _boxes[entry.id] = 0;
    notifyListeners();
  }

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

  /// Words in training order: the weakest boxes first, shuffled inside a box
  /// so a round never feels the same twice.
  List<VocabEntry> trainingOrder(List<VocabEntry> pool, {Random? random}) {
    final Random rnd = random ?? Random();
    final List<VocabEntry> shuffled = List<VocabEntry>.of(pool)..shuffle(rnd);
    shuffled.sort((VocabEntry a, VocabEntry b) =>
        boxOf(a).compareTo(boxOf(b)));
    return shuffled;
  }

  void recordAnswer({required bool correct}) {
    _answered++;
    if (correct) {
      _correct++;
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
    } else {
      _streak = 0;
    }
    notifyListeners();
  }

  void reset() {
    _boxes.clear();
    _answered = 0;
    _correct = 0;
    _streak = 0;
    _bestStreak = 0;
    notifyListeners();
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
