import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../state/custom_cards.dart';
import '../state/daily_card_store.dart';
import 'curriculum.dart';
import 'knowledge/knowledge_data.dart';
import 'quran_vocab.dart';
import 'vocabulary_data.dart';

/// Alles, was der Lernkern über Inhalte wissen muss — und nicht mehr.
///
/// Bis hierher griff [LearningState] direkt auf die arabischen Konstanten zu.
/// Damit weitere Fächer dazukommen können, ohne den Lernkern anzufassen,
/// liegt der Inhalt jetzt hinter dieser Schnittstelle — dasselbe Muster wie
/// bei `SpeechBackend` und `ReminderBackend`, und ebenso im Test ersetzbar.
abstract class ContentRegistry {
  /// Alle Themen, aus denen geübt werden kann.
  List<VocabCategory> get categories;

  /// Alle Einträge, die in die Wiederholung gehören.
  List<VocabEntry> get entries;

  /// Die Bereiche des Lernwegs, in der Reihenfolge der Startseite.
  List<CategoryGroup> get groups;

  VocabCategory? categoryById(String id);
}

/// Der Inhalt der ausgelieferten App.
///
/// Wichtig: Der arabische Bestand (`kAllEntries`, `kAllCategories`) bleibt für
/// sich. Die Datentests fordern für jeden Eintrag dort arabische Schrift und
/// keine lateinischen Buchstaben — Wissensinhalte werden deshalb nie
/// eingemischt, sondern erst hier, eine Ebene höher, zusammengeführt.
class AppContent implements ContentRegistry {
  const AppContent();

  @override
  List<VocabCategory> get categories =>
      <VocabCategory>[...kAllCategories, ...kKnowledgeCategories];

  @override
  List<VocabEntry> get entries =>
      <VocabEntry>[...kAllEntries, ...kKnowledgeEntries];

  @override
  List<CategoryGroup> get groups =>
      <CategoryGroup>[...kGroups, ...kKnowledgeGroups];

  @override
  VocabCategory? categoryById(String id) {
    for (final VocabCategory category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Die Quran-Wörter — für das gleichnamige Abzeichen.
  static const String quranCategoryId = 'quran_woerter';
}

/// Ein fester Inhalt für Tests und Vorschauen.
class FixedContent implements ContentRegistry {
  const FixedContent(this._groups);

  final List<CategoryGroup> _groups;

  @override
  List<CategoryGroup> get groups => _groups;

  @override
  List<VocabCategory> get categories =>
      <VocabCategory>[for (final CategoryGroup g in _groups) ...g.categories];

  @override
  List<VocabEntry> get entries =>
      <VocabEntry>[for (final VocabCategory c in categories) ...c.entries];

  @override
  VocabCategory? categoryById(String id) {
    for (final VocabCategory category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}

/// Der eingebaute Inhalt plus alles, was aus dem Bereich „Heute" kommt.
///
/// Die Karten kommen erst hier dazu, eine Ebene über den Konstanten: So
/// bleiben `kAllEntries` und `kGroups` das, was die Datentests prüfen — rein
/// arabisch und lückenlos vom Lernweg abgedeckt.
///
/// Zwei Quellen, zwei Themen: **Meine Karten** sind selbst gemerkt,
/// **Tagesfunde** kommen von allein. Sie stehen nebeneinander und nicht in
/// einem Topf, damit man sie auseinanderhalten und einzeln wegwerfen kann.
class ContentWithCustomCards implements ContentRegistry {
  const ContentWithCustomCards(this.base, this.store, [this.daily]);

  final ContentRegistry base;
  final CustomCardStore store;

  /// Die Tagesfunde. Fehlen sie, verhält sich alles wie vorher — so bleiben
  /// Tests und Vorschauen ohne diesen Speicher gültig.
  final DailyCardStore? daily;

  /// Das Thema, unter dem gemerkte Funde erscheinen.
  static const String customCategoryId = 'meine_karten';
  static const String customGroupId = 'gemerkt';

  /// Das Thema, unter dem der Tagesstoff landet.
  static const String dailyCategoryId = 'tagesfunde';

  /// Erst wenn etwas da ist, taucht das Thema überhaupt auf — ein leeres
  /// Fach auf der Startseite wäre nur im Weg.
  List<CategoryGroup> get _custom {
    final List<VocabEntry> cards = store.cards;
    final List<VocabEntry> funde = daily?.cards ?? const <VocabEntry>[];
    if (cards.isEmpty && funde.isEmpty) return const <CategoryGroup>[];
    return <CategoryGroup>[
      CategoryGroup(
        id: customGroupId,
        name: 'Aus dem Alltag',
        description: 'Was du dir aufgehoben hast — und was der Tag brachte.',
        icon: Icons.bookmark,
        categories: <VocabCategory>[
          if (cards.isNotEmpty)
            VocabCategory(
              id: customCategoryId,
              name: 'Meine Karten',
              icon: Icons.bookmark_added,
              color: const Color(0xFF6A4C93),
              softColor: const Color(0xFFEDE7F6),
              script: TextScript.latin,
              entries: cards,
            ),
          if (funde.isNotEmpty)
            VocabCategory(
              id: dailyCategoryId,
              name: 'Tagesfunde',
              icon: Icons.auto_awesome,
              color: const Color(0xFF1F7A6C),
              softColor: const Color(0xFFDDF0EC),
              script: TextScript.latin,
              entries: funde,
            ),
        ],
      ),
    ];
  }

  @override
  List<CategoryGroup> get groups => <CategoryGroup>[...base.groups, ..._custom];

  @override
  List<VocabCategory> get categories => <VocabCategory>[
        ...base.categories,
        for (final CategoryGroup g in _custom) ...g.categories,
      ];

  @override
  List<VocabEntry> get entries => <VocabEntry>[
        ...base.entries,
        ...store.cards,
        ...?daily?.cards,
      ];

  @override
  VocabCategory? categoryById(String id) {
    if (id == customCategoryId || id == dailyCategoryId) {
      for (final CategoryGroup g in _custom) {
        for (final VocabCategory c in g.categories) {
          if (c.id == id) return c;
        }
      }
      return null;
    }
    return base.categoryById(id);
  }
}

/// Wird benutzt, solange nichts anderes gesetzt ist.
const ContentRegistry kDefaultContent = AppContent();

/// Nicht mehr gebraucht, sobald alle Aufrufer die Registry durchreichen —
/// bis dahin die eine Stelle, an der die Quran-Kategorie bekannt sein muss.
const VocabCategory kQuranCategory = kQuranWords;
