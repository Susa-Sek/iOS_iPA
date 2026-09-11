import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';
import 'quiz_builder.dart';

/// Was auf einer Karte des Feeds steht.
enum ShortKind {
  /// Ein Begriff mit Bedeutung und Erklärung — nur zu lesen.
  fakt,

  /// Eine Frage mit vier Antworten.
  frage,
}

/// Eine Karte des Feeds.
///
/// Bei einer Frage steckt die fertige Aufgabe in [question] — gebaut von
/// `buildQuizRound`, damit es für „vier Antworten, eine stimmt" nur eine
/// Stelle in der App gibt.
@immutable
class ShortItem {
  const ShortItem.fakt(this.entry)
      : kind = ShortKind.fakt,
        question = null;

  ShortItem.frage(QuizQuestion frage)
      : kind = ShortKind.frage,
        entry = frage.entry,
        question = frage;

  final ShortKind kind;

  /// Der Eintrag dahinter — für Lernstand und Erklärung.
  final VocabEntry entry;

  /// Nur bei [ShortKind.frage] gesetzt.
  final QuizQuestion? question;

  /// Die vier Antworten, gemischt. Bei einem Fakt leer.
  List<String> get options => question?.options ?? const <String>[];

  @override
  String toString() => '${kind.name}: ${entry.german}';
}

/// Baut den Feed eines Themas: erst etwas erfahren, dann geprüft werden.
///
/// Reine Funktion wie `buildQuizRound` und `buildSession` — ohne Widgets und
/// ohne Kontext, damit die Reihenfolge prüfbar ist, bevor es einen
/// Bildschirm gibt.
///
/// **Die Regeln.** Der Feed beginnt mit einem Fakt: Wer ein Thema aufschlägt,
/// soll zuerst etwas erfahren und nicht zuerst geprüft werden. Die Fragen
/// werden gleichmäßig auf die Lücken hinter den Fakten verteilt — bei gleich
/// vielen Fakten wie Fragen wechseln sich beide sauber ab, und bei mehr
/// Fragen bleibt am Ende kein Block aus lauter Fragen übrig. Jede Karte des
/// Themas kommt genau einmal vor.
///
/// Innerhalb ihrer Art bleibt die **Reihenfolge des Themas** erhalten. Das
/// ist der Grund, warum hier nichts gemischt wird: Die Karten sind in der
/// Reihenfolge geschrieben, in der sie aufeinander aufbauen, und eine Frage
/// landet dadurch ungefähr dort, wo sie auch beim Schreiben stand. Gemischt
/// werden nur die vier Antworten einer Frage.
List<ShortItem> buildShorts({
  required VocabCategory category,
  required Random random,
}) {
  final List<VocabEntry> entries = category.entries;
  if (entries.isEmpty) return const <ShortItem>[];

  final List<VocabEntry> fakten = <VocabEntry>[
    for (final VocabEntry e in entries)
      if (e.question == null) e,
  ];
  final List<VocabEntry> fragen = <VocabEntry>[
    for (final VocabEntry e in entries)
      if (e.question != null) e,
  ];

  // Die Aufgaben entstehen an einer Stelle — mit den mitgelieferten
  // Ablenkern, sonst aufgefüllt aus dem Thema.
  final List<QuizQuestion> aufgaben = buildQuizRound(
    ordered: fragen,
    pool: entries,
    direction: QuizDirection.arabicToGerman,
    random: random,
    count: fragen.length,
  );

  if (fakten.isEmpty) {
    return <ShortItem>[
      for (final QuizQuestion q in aufgaben) ShortItem.frage(q),
    ];
  }

  final List<ShortItem> feed = <ShortItem>[];
  int gesetzt = 0;
  for (int i = 0; i < fakten.length; i++) {
    feed.add(ShortItem.fakt(fakten[i]));
    // Gleichmäßig verteilen: Nach dem i-ten Fakt sind so viele Fragen dran,
    // dass am Ende keine übrig bleiben und zwischendurch kein Loch entsteht.
    final int bisHier = (i + 1) * aufgaben.length ~/ fakten.length;
    while (gesetzt < bisHier) {
      feed.add(ShortItem.frage(aufgaben[gesetzt]));
      gesetzt++;
    }
  }
  return feed;
}

/// Die längste Folge von Fragen ohne einen Fakt dazwischen.
///
/// Steht hier und nicht im Test, weil es die Zusage der Verteilung ist: Bei
/// höchstens so vielen Fragen wie Fakten wechseln sich beide ab.
int longestQuestionRun(List<ShortItem> feed) {
  int laengste = 0;
  int lauf = 0;
  for (final ShortItem item in feed) {
    lauf = item.kind == ShortKind.frage ? lauf + 1 : 0;
    if (lauf > laengste) laengste = lauf;
  }
  return laengste;
}
