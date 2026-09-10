import 'package:flutter/material.dart';

import 'arabic.dart';

/// Welche Schrift ein Eintrag benutzt — entscheidet über die Leserichtung.
enum TextScript {
  /// Deutsch, Zahlen, Fachbegriffe: von links nach rechts.
  latin,

  /// Arabisch: von rechts nach links.
  arabic;

  bool get isRightToLeft => this == TextScript.arabic;
}

/// Ein Lerneintrag.
///
/// Ursprünglich für Vokabeln gebaut (Deutsch, arabische Schrift, Lautschrift)
/// und inzwischen auch für Wissenskarten: [answer] trägt dann die Antwort
/// statt eines arabischen Wortes.
///
/// Die drei ersten Felder bleiben bewusst positional und in dieser
/// Reihenfolge — sie werden in `lib/data/` rund tausendmal so geschrieben,
/// und [id] aus ihnen gebildet. [id] ist zugleich der Schlüssel im
/// gespeicherten Lernstand: Ändert sich das Schema, verlieren alle
/// bestehenden Installationen ihren Fortschritt.
@immutable
class VocabEntry {
  const VocabEntry(
    this.german,
    this.arabic,
    this.transliteration, {
    this.question,
    this.distractors = const <String>[],
    this.explanation,
    this.source,
    this.script = TextScript.arabic,
  });

  /// Eine Wissenskarte: Begriff und Erklärung, ohne Lautschrift.
  const VocabEntry.fact(
    String term,
    String meaning, {
    String? explanation,
    String? source,
  }) : this(term, meaning, '',
            explanation: explanation,
            source: source,
            script: TextScript.latin);

  /// Eine Wissensfrage mit vier Antworten: die richtige plus drei falsche.
  const VocabEntry.question(
    String question,
    String answer, {
    required List<String> distractors,
    String? explanation,
    String? source,
  }) : this(question, answer, '',
            question: question,
            distractors: distractors,
            explanation: explanation,
            source: source,
            script: TextScript.latin);

  /// Die deutsche Seite — bei Wissenskarten der Begriff, bei Fragen die Frage.
  final String german;

  /// Die andere Seite: arabisches Wort oder Antwort.
  final String arabic;

  final String transliteration;

  /// Ausformulierte Frage, falls sich der Eintrag nicht als Begriffspaar
  /// darstellen lässt.
  final String? question;

  /// Mitgelieferte Falschantworten. Sind sie leer, baut das Quiz die
  /// Ablenker wie bisher aus anderen Einträgen.
  final List<String> distractors;

  /// Ein bis zwei Sätze, warum die Antwort stimmt — bei Wissensfragen der
  /// eigentliche Lerneffekt.
  final String? explanation;

  /// Woher der Inhalt stammt, falls er nicht aus der App selbst kommt.
  final String? source;

  /// Leserichtung der [arabic]-Seite.
  final TextScript script;

  /// Die Antwortseite unter ihrem sprechenden Namen.
  String get answer => arabic;

  /// Der Text, der als Aufgabe gezeigt wird.
  String get prompt => question ?? german;

  /// Ob der Eintrag Sprache übt (arabische Schrift) oder Wissen abfragt.
  bool get isLanguage => script == TextScript.arabic;

  /// Stable identifier, used to remember which words have been learned.
  String get id => '$german|$arabic';

  /// Arabic without Tashkīl, so a search finds a word whether or not the
  /// vowel marks are typed.
  String get arabicPlain => withoutTashkil(arabic);

  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return german.toLowerCase().contains(q) ||
        transliteration.toLowerCase().contains(q) ||
        (explanation?.toLowerCase().contains(q) ?? false) ||
        arabic.toLowerCase().contains(q) ||
        arabicPlain.contains(withoutTashkil(q));
  }
}

/// A themed group of vocabulary, e.g. "Im Restaurant".
@immutable
class VocabCategory {
  const VocabCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.entries,
    this.arabicName,
    this.script = TextScript.arabic,
  });

  final String id;
  final String name;

  /// Nur bei arabischen Themen gesetzt.
  final String? arabicName;

  /// Leserichtung der Einträge dieses Themas.
  final TextScript script;

  /// Ob das Thema Sprache übt — davon hängt ab, welche Übungen sinnvoll sind.
  bool get isLanguage => script == TextScript.arabic;

  final IconData icon;

  /// The category's accent colour and a translucent version of it, kept as
  /// explicit constants so no colour has to be derived at runtime.
  final Color color;
  final Color softColor;
  final List<VocabEntry> entries;
}

/// A letter of the Arabic alphabet with its four positional forms.
@immutable
class ArabicLetter {
  const ArabicLetter({
    required this.isolated,
    required this.name,
    required this.transliteration,
    required this.initial,
    required this.medial,
    required this.finalForm,
    required this.hint,
  });

  final String isolated;
  final String name;
  final String transliteration;
  final String initial;
  final String medial;
  final String finalForm;

  /// Short German pronunciation hint.
  final String hint;
}

/// A Tashkīl mark — the short vowels and reading signs that turn a row of
/// consonants into a pronounceable word.
@immutable
class ArabicDiacritic {
  const ArabicDiacritic({
    required this.symbol,
    required this.name,
    required this.arabicName,
    required this.example,
    required this.sound,
    required this.hint,
  });

  /// The mark on a dotted circle, e.g. "◌َ".
  final String symbol;

  final String name;
  final String arabicName;

  /// The mark on the letter Bāʾ, e.g. "بَ".
  final String example;

  /// How that example is pronounced, e.g. "ba".
  final String sound;

  final String hint;
}

/// Ein Bereich des Lernwegs — mehrere Themen, die zusammengehören.
///
/// Mit rund 30 Themen wäre eine einzige Liste unübersichtlich; die Bereiche
/// geben dem Wortschatz eine Reihenfolge, von den ersten Wörtern bis zu den
/// Bausteinen der Sprache.
@immutable
class CategoryGroup {
  const CategoryGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.categories,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<VocabCategory> categories;

  List<VocabEntry> get entries =>
      <VocabEntry>[for (final VocabCategory c in categories) ...c.entries];
}

/// Eine Person in der Konjugationstabelle.
@immutable
class VerbForm {
  const VerbForm(this.person, this.past, this.present, this.transliteration);

  /// "ich", "du", "er" …
  final String person;

  /// Vergangenheit (الْمَاضِي) und Gegenwart (الْمُضَارِع).
  final String past;
  final String present;

  /// Lautschrift beider Formen, durch " / " getrennt.
  final String transliteration;
}

/// Ein Verb mit seiner vollständigen Konjugation.
@immutable
class Verb {
  const Verb({
    required this.german,
    required this.root,
    required this.past,
    required this.present,
    required this.transliteration,
    required this.forms,
  });

  final String german;

  /// Die drei Wurzelbuchstaben, z. B. "ك · ت · ب".
  final String root;

  /// Die Grundform: er schrieb / er schreibt.
  final String past;
  final String present;
  final String transliteration;

  final List<VerbForm> forms;
}
