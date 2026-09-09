import 'dart:math';

/// How well one word is known, and when it should come back.
///
/// The app uses a Leitner schedule: every correct answer moves a word one
/// step up and pushes the next repetition further away, a wrong answer sends
/// it back to the start. That is what makes vocabulary stick over weeks
/// instead of over one session.
class WordProgress {
  WordProgress({this.box = 0, this.due, this.lastAnswered});

  /// Days until the next repetition, per box.
  static const List<int> intervalDays = <int>[0, 1, 3, 7, 21, 60];

  static const int maxBox = 5;

  /// From this box on, a word counts as "sitzt" in the progress display.
  static const int learnedFromBox = 3;

  int box;
  DateTime? due;
  DateTime? lastAnswered;

  bool get isLearned => box >= learnedFromBox;

  /// Due today (or overdue). A word that was never answered is due.
  bool isDue(DateTime now) {
    final DateTime? d = due;
    if (d == null) return true;
    return !d.isAfter(_endOfDay(now));
  }

  WordProgress promote(DateTime now) => WordProgress(
        box: min(maxBox, box + 1),
        lastAnswered: now,
        due: _dayAfter(now, intervalDays[min(maxBox, box + 1)]),
      );

  WordProgress demote(DateTime now) => WordProgress(
        box: 0,
        lastAnswered: now,
        due: _dayAfter(now, intervalDays[0]),
      );

  /// Marked by hand in the word list, without a review history.
  WordProgress setBox(int value, DateTime now) {
    final int b = value.clamp(0, maxBox);
    return WordProgress(
      box: b,
      lastAnswered: now,
      due: _dayAfter(now, intervalDays[b]),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'b': box,
        if (due != null) 'd': due!.toIso8601String(),
        if (lastAnswered != null) 'l': lastAnswered!.toIso8601String(),
      };

  static WordProgress fromJson(Map<String, dynamic> json) => WordProgress(
        box: (json['b'] as num?)?.toInt() ?? 0,
        due: _parse(json['d']),
        lastAnswered: _parse(json['l']),
      );

  static DateTime? _parse(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

DateTime _endOfDay(DateTime day) =>
    DateTime(day.year, day.month, day.day, 23, 59, 59);

DateTime _dayAfter(DateTime from, int days) =>
    DateTime(from.year, from.month, from.day).add(Duration(days: days));

/// Midnight of the given day — used as the key for the daily statistics.
DateTime dayOf(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

/// Day key in the stored statistics, e.g. "2026-09-09".
String dayKey(DateTime moment) {
  final String m = moment.month.toString().padLeft(2, '0');
  final String d = moment.day.toString().padLeft(2, '0');
  return '${moment.year}-$m-$d';
}
