import 'package:flutter/foundation.dart';

/// One word of a verse with its meaning — the basis of the word-by-word
/// reader, where the learner taps a word and sees what it means.
@immutable
class QuranWord {
  const QuranWord(this.arabic, this.transliteration, this.german);

  final String arabic;
  final String transliteration;
  final String german;
}

/// A single verse. The Arabic text is assembled from [words], so the
/// displayed verse and the word-by-word breakdown can never drift apart.
@immutable
class QuranVerse {
  const QuranVerse({
    required this.number,
    required this.words,
    required this.german,
  });

  final int number;
  final List<QuranWord> words;

  /// A plain German rendering of the whole verse — an aid to understanding,
  /// not a substitute for an established translation.
  final String german;

  String get arabic => words.map((QuranWord w) => w.arabic).join(' ');
}

@immutable
class QuranSura {
  const QuranSura({
    required this.number,
    required this.arabicName,
    required this.name,
    required this.meaning,
    required this.about,
    required this.verses,
    this.opensWithBasmala = true,
  });

  final int number;
  final String arabicName;

  /// Transcribed name, e.g. "Al-Fātiḥa".
  final String name;

  /// What the name means in German.
  final String meaning;

  /// One or two sentences of context.
  final String about;

  final List<QuranVerse> verses;

  /// Whether the Basmala is shown as an opening line above verse 1. In
  /// Al-Fātiḥa the Basmala is verse 1 itself, so it is not repeated.
  final bool opensWithBasmala;

  int get verseCount => verses.length;
}

/// A three-letter root and the words built on it — the mechanism that makes
/// Arabic vocabulary learnable instead of endless.
@immutable
class ArabicRoot {
  const ArabicRoot({
    required this.letters,
    required this.meaning,
    required this.derivations,
  });

  /// The bare root, e.g. "ك ت ب".
  final String letters;

  /// The idea the root carries, e.g. "schreiben".
  final String meaning;

  final List<QuranWord> derivations;
}
