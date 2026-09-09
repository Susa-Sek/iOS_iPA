import 'package:flutter/material.dart';

/// A single vocabulary entry: the German word, its Arabic script and a
/// transliteration ("Lautschrift") that shows how the word is pronounced.
@immutable
class VocabEntry {
  const VocabEntry(this.german, this.arabic, this.transliteration);

  final String german;
  final String arabic;
  final String transliteration;

  /// Stable identifier, used to remember which words have been learned.
  String get id => '$german|$arabic';

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return german.toLowerCase().contains(q) ||
        transliteration.toLowerCase().contains(q) ||
        arabic.contains(q);
  }
}

/// A themed group of vocabulary, e.g. "Im Restaurant".
@immutable
class VocabCategory {
  const VocabCategory({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.entries,
  });

  final String id;
  final String name;
  final String arabicName;
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
