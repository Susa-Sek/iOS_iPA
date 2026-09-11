import 'package:flutter/material.dart';

/// A badge and the condition that unlocks it.
///
/// The condition is a plain function over the numbers the app already keeps,
/// so a badge can never disagree with the statistics it is based on.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.target,
    required this.progress,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;

  /// What has to be reached.
  final int target;

  /// How far the learner is, given the current numbers.
  final int Function(AchievementStats stats) progress;

  bool isUnlocked(AchievementStats stats) => progress(stats) >= target;

  double ratio(AchievementStats stats) =>
      target == 0 ? 1 : (progress(stats) / target).clamp(0, 1).toDouble();
}

/// Everything the badges are judged on.
@immutable
class AchievementStats {
  const AchievementStats({
    required this.learnedWords,
    required this.dayStreak,
    required this.answers,
    required this.perfectRounds,
    required this.completedCategories,
    required this.learnedQuranWords,
    required this.level,
    this.lessonsDone = 0,
    this.topicsUnderstood = 0,
    this.shortsDone = 0,
    this.questDays = 0,
    this.freezesEarned = 0,
  });

  final int learnedWords;
  final int dayStreak;
  final int answers;
  final int perfectRounds;
  final int completedCategories;
  final int learnedQuranWords;
  final int level;

  /// Durchgearbeitete Lektionen im Fach Wissen.
  ///
  /// Eigene Zahlen, weil dort anders gelernt wird: Nicht die abgehakte Karte
  /// zählt, sondern die Lektion und das verstandene Thema.
  final int lessonsDone;
  final int topicsUnderstood;

  /// Themen, die im Feed bis zum Ende durchgewischt wurden.
  final int shortsDone;

  /// Tage, an denen alle drei Tagesaufgaben erledigt waren.
  final int questDays;

  /// Verdiente Jokertage — auch die schon eingesetzten.
  final int freezesEarned;
}
