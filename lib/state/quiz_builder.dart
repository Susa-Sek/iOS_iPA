import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';

/// Aus welcher Richtung gefragt wird.
enum QuizDirection {
  /// Arabisches Wort steht da, die deutsche Bedeutung ist gesucht.
  arabicToGerman,

  /// Deutsches Wort steht da, das arabische ist gesucht.
  germanToArabic,

  /// Nur das gesprochene Wort ist gegeben — die schwerste Richtung.
  listening;

  String get label => switch (this) {
        QuizDirection.arabicToGerman => 'Arabisch → Deutsch',
        QuizDirection.germanToArabic => 'Deutsch → Arabisch',
        QuizDirection.listening => 'Hören → Deutsch',
      };
}

/// Eine fertige Frage: was gezeigt wird, welche Antworten zur Wahl stehen und
/// welche stimmt.
///
/// Die Antworten sind **Texte**, keine Einträge. Bei Wissensfragen kommen die
/// Falschantworten mitgeliefert („Donau", „Rhein"), und die sind nun einmal
/// kein `VocabEntry`.
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.entry,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.promptIsArabic,
    required this.answersAreArabic,
  });

  /// Der Eintrag, um den es geht — für Lernstand und Vorlesen.
  final VocabEntry entry;

  /// Was oben steht.
  final String prompt;

  /// Vier Antworttexte, gemischt.
  final List<String> options;

  /// Welcher davon richtig ist.
  final String answer;

  final bool promptIsArabic;
  final bool answersAreArabic;

  String? get explanation => entry.explanation;
  String? get source => entry.source;

  bool isCorrect(String option) => option == answer;
}

/// Wie viele Fragen eine Runde hat.
const int kQuestionsPerRound = 10;

/// Baut eine Runde — ohne Widgets, ohne Kontext, damit sie prüfbar ist.
///
/// [ordered] kommt bereits in Übungsreihenfolge (fällige und schwache Wörter
/// zuerst); [pool] liefert die Ablenker für Vokabeln, die keine eigenen
/// mitbringen.
List<QuizQuestion> buildQuizRound({
  required List<VocabEntry> ordered,
  required List<VocabEntry> pool,
  required QuizDirection direction,
  required Random random,
  int count = kQuestionsPerRound,
}) {
  final int take = min(count, ordered.length);
  return <QuizQuestion>[
    for (final VocabEntry entry in ordered.take(take))
      _questionFor(
        entry: entry,
        pool: pool,
        direction: direction,
        random: random,
      ),
  ];
}

QuizQuestion _questionFor({
  required VocabEntry entry,
  required List<VocabEntry> pool,
  required QuizDirection direction,
  required Random random,
}) {
  // Eine Wissensfrage hat nur eine Richtung und bringt ihre Ablenker mit.
  if (!entry.isLanguage || entry.distractors.isNotEmpty) {
    final List<String> options = <String>[
      entry.answer,
      ...entry.distractors.take(3),
    ];
    _fillUp(options, entry, pool, random, useAnswerSide: true);
    return QuizQuestion(
      entry: entry,
      prompt: entry.prompt,
      options: options..shuffle(random),
      answer: entry.answer,
      promptIsArabic: false,
      answersAreArabic: false,
    );
  }

  // Vokabel: Die Ablenker kommen wie bisher aus anderen Wörtern.
  final bool askArabic = direction != QuizDirection.germanToArabic;
  final List<String> options = <String>[
    askArabic ? entry.german : entry.arabic,
  ];
  _fillUp(options, entry, pool, random, useAnswerSide: !askArabic);

  return QuizQuestion(
    entry: entry,
    prompt: askArabic ? entry.arabic : entry.german,
    options: options..shuffle(random),
    answer: askArabic ? entry.german : entry.arabic,
    promptIsArabic: askArabic,
    answersAreArabic: !askArabic,
  );
}

/// Füllt auf vier Antworten auf, ohne die richtige zu wiederholen.
///
/// Ablenker kommen zuerst aus Einträgen derselben Art. Sonst stünden, sobald
/// Wortschatz und Wissen im selben Vorrat liegen, unter „Kragenhai" drei
/// arabische Wörter zur Wahl — die Frage wäre ohne Nachdenken zu lösen.
void _fillUp(
  List<String> options,
  VocabEntry entry,
  List<VocabEntry> pool,
  Random random, {
  required bool useAnswerSide,
}) {
  if (options.length >= 4) return;
  final List<VocabEntry> candidates = List<VocabEntry>.of(pool)
    ..shuffle(random);

  // Erst die passenden, danach — nur falls nötig — alle übrigen.
  for (final bool sameKind in <bool>[true, false]) {
    for (final VocabEntry candidate in candidates) {
      if (options.length == 4) return;
      if (candidate.id == entry.id) continue;
      if ((candidate.isLanguage == entry.isLanguage) != sameKind) continue;
      final String text = useAnswerSide ? candidate.arabic : candidate.german;
      if (text.trim().isEmpty || options.contains(text)) continue;
      options.add(text);
    }
  }
}
