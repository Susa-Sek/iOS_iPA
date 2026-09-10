import '../models/vocabulary.dart';
import 'curriculum.dart';
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
  List<VocabCategory> get categories => kAllCategories;

  @override
  List<VocabEntry> get entries => kAllEntries;

  @override
  List<CategoryGroup> get groups => kGroups;

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

/// Wird benutzt, solange nichts anderes gesetzt ist.
const ContentRegistry kDefaultContent = AppContent();

/// Nicht mehr gebraucht, sobald alle Aufrufer die Registry durchreichen —
/// bis dahin die eine Stelle, an der die Quran-Kategorie bekannt sein muss.
const VocabCategory kQuranCategory = kQuranWords;
