/// Helpers for Arabic text that carries Tashkīl (Fatḥa, Kasra, Ḍamma …).
///
/// The marks are their own code points that sit on top of the preceding
/// letter. Anything that walks through a word letter by letter — the
/// "Wort bauen" exercise — has to keep a letter and its marks together, and
/// anything that compares words — the search — has to be able to ignore them.
library;

/// Combining marks: Tashkīl, Qurʾānic annotations, the dagger Alif and the
/// Tatwīl (ـ), which stretches a letter without changing it.
bool isArabicMark(int codeUnit) =>
    (codeUnit >= 0x064B && codeUnit <= 0x065F) ||
    codeUnit == 0x0640 ||
    codeUnit == 0x0670 ||
    (codeUnit >= 0x06D6 && codeUnit <= 0x06ED);

/// Splits [text] into units of one base character plus the marks that belong
/// to it, so `'كِتَاب'` becomes `['كِ', 'تَ', 'ا', 'ب']`.
List<String> arabicLetterUnits(String text) {
  final List<String> units = <String>[];
  final StringBuffer current = StringBuffer();

  void flush() {
    if (current.isNotEmpty) {
      units.add(current.toString());
      current.clear();
    }
  }

  for (final int rune in text.runes) {
    if (isArabicMark(rune) && current.isNotEmpty) {
      current.writeCharCode(rune);
    } else {
      flush();
      current.writeCharCode(rune);
    }
  }
  flush();
  return units;
}

/// The same word without any Tashkīl — used to compare and search.
String withoutTashkil(String text) => String.fromCharCodes(
      text.runes.where((int rune) => !isArabicMark(rune)),
    );

/// Whether [text] carries at least one Tashkīl mark.
bool hasTashkil(String text) => text.runes.any(isArabicMark);
