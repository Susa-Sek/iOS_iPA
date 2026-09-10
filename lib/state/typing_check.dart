import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';

/// Wie eine getippte Antwort ausgefallen ist.
enum TypingVerdict {
  /// Wort für Wort richtig.
  exact,

  /// Bis auf Kleinigkeiten richtig — ein Buchstabe daneben, ein fehlender
  /// Artikel, ein Umlaut ohne Punkte. Zählt als gewusst, die richtige
  /// Schreibweise wird trotzdem gezeigt.
  almost,

  wrong,
}

@immutable
class TypingResult {
  const TypingResult(this.verdict, this.answer);

  final TypingVerdict verdict;

  /// Die richtige Schreibweise, wie sie danach angezeigt wird.
  final String answer;

  bool get isCorrect => verdict != TypingVerdict.wrong;
}

/// Prüft eine getippte Antwort gegen die Seite, die getippt werden soll.
///
/// Bewusst nachsichtig: Geprüft wird, ob jemand die Antwort **weiß**, nicht,
/// ob er sie fehlerfrei tippt. Groß- und Kleinschreibung, Umlautpunkte,
/// Satzzeichen und ein vorangestellter Artikel entscheiden nichts.
TypingResult checkTyped(String input, VocabEntry entry) {
  final String answer = typedTarget(entry);
  final String a = _normalize(input);
  final String b = _normalize(answer);

  if (a.isEmpty) return TypingResult(TypingVerdict.wrong, answer);
  if (a == b) return TypingResult(TypingVerdict.exact, answer);

  // Ein Tippfehler in einem längeren Wort ist kein Nichtwissen — bei kurzen
  // Wörtern dagegen wäre jede Abweichung schon ein anderes Wort.
  final int erlaubt = b.length >= 8 ? 2 : (b.length >= 5 ? 1 : 0);
  if (erlaubt == 0) return TypingResult(TypingVerdict.wrong, answer);

  final int abstand = _distance(a, b);
  if (abstand > erlaubt) return TypingResult(TypingVerdict.wrong, answer);

  // Nachsicht darf nie so weit gehen, dass eine falsche Antwort durchgeht.
  // „Totes Meer" ist von „Rotes Meer" nur einen Buchstaben entfernt — und
  // trotzdem ein anderes Meer. Liegt die Eingabe genauso nah an einem
  // Ablenker, zählt sie nicht.
  for (final String falsch in entry.distractors) {
    if (_distance(a, _normalize(falsch)) <= abstand) {
      return TypingResult(TypingVerdict.wrong, answer);
    }
  }
  return TypingResult(TypingVerdict.almost, answer);
}

/// Artikel, die vorn wegfallen dürfen: „Die Leber" und „Leber" sind dieselbe
/// Antwort.
const Set<String> _artikel = <String>{
  'der', 'die', 'das', 'den', 'dem', 'des',
  'ein', 'eine', 'einen', 'einem', 'einer', 'eines',
};

/// Bringt eine Eingabe auf die Form, in der verglichen wird.
///
/// Öffentlich, weil die Datentests damit prüfen, dass kein Ablenker nach dem
/// Normalisieren mit seiner eigenen Antwort zusammenfällt — sonst würde er
/// beim Tippen als richtig durchgehen.
String normalizeAnswer(String text) => _normalize(text);

String _normalize(String text) {
  final StringBuffer out = StringBuffer();
  for (final int rune in text.toLowerCase().runes) {
    final String c = String.fromCharCode(rune);
    final String? gefaltet = _fold[c];
    if (gefaltet != null) {
      out.write(gefaltet);
    } else if (RegExp(r'[a-z0-9]').hasMatch(c)) {
      out.write(c);
    } else if (c == ' ' || c == '-' || c == '\t' || c == '\n') {
      out.write(' ');
    }
    // Alles andere — Punkt, Komma, Fragezeichen, Anführungszeichen — fällt
    // weg. Wer die Antwort weiß, soll nicht an einem Komma scheitern.
  }

  final List<String> woerter = out
      .toString()
      .split(' ')
      .where((String w) => w.isNotEmpty)
      .toList();
  if (woerter.length > 1 && _artikel.contains(woerter.first)) {
    woerter.removeAt(0);
  }
  return woerter.join(' ');
}

/// Buchstaben, die auf ihre Grundform fallen. „Aquator" gilt als „Äquator".
const Map<String, String> _fold = <String, String>{
  'ä': 'a', 'ö': 'o', 'ü': 'u', 'ß': 'ss',
  'á': 'a', 'à': 'a', 'â': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u',
  'ç': 'c', 'ñ': 'n', 'ř': 'r', 'š': 's', 'ž': 'z',
  // Tief- und hochgestellte Ziffern werden zu gewöhnlichen. Ohne das fielen
  // sie beim Normalisieren weg — „H₂O" und „H₂O₂" wären dieselbe Antwort,
  // und wer „H2O" tippt, hätte unrecht.
  '₀': '0', '₁': '1', '₂': '2', '₃': '3', '₄': '4',
  '₅': '5', '₆': '6', '₇': '7', '₈': '8', '₉': '9',
  '⁰': '0', '¹': '1', '²': '2', '³': '3', '⁴': '4',
  '⁵': '5', '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9',
};

/// Levenshtein-Abstand: wie viele Zeichen man ändern, einfügen oder löschen
/// müsste. Zwei Zeilen statt einer ganzen Matrix — mehr wird nie gebraucht.
int _distance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  List<int> vorher = List<int>.generate(b.length + 1, (int i) => i);
  List<int> jetzt = List<int>.filled(b.length + 1, 0);

  for (int i = 0; i < a.length; i++) {
    jetzt[0] = i + 1;
    for (int j = 0; j < b.length; j++) {
      final int kosten = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      jetzt[j + 1] = min(
        min(jetzt[j] + 1, vorher[j + 1] + 1),
        vorher[j] + kosten,
      );
    }
    final List<int> tausch = vorher;
    vorher = jetzt;
    jetzt = tausch;
  }
  return vorher[b.length];
}

/// Ob ein Eintrag sich zum Tippen eignet.
///
/// Ganze Sätze abzutippen prüft Geduld, nicht Wissen — und ein arabisches
/// Wort lässt sich auf einer deutschen Tastatur gar nicht eingeben. Getippt
/// wird deshalb immer die deutsche Seite.
bool isTypeable(VocabEntry entry, {int maxLength = 24}) {
  final String answer = entry.answer.trim();
  if (answer.isEmpty || answer.length > maxLength) return false;
  final String getippt = typedTarget(entry).trim();
  if (getippt.isEmpty || getippt.length > maxLength) return false;
  // Ein Satzende heißt: Das ist ein Satz, keine Antwort.
  if (getippt.contains('. ')) return false;
  return _normalize(getippt).isNotEmpty;
}

/// Was bei einem Eintrag getippt werden soll.
///
/// Bei einer Vokabel die deutsche Seite: Ein arabisches Wort lässt sich auf
/// einer deutschen Tastatur nicht eingeben. Bei einer Wissenskarte die
/// Antwort.
String typedTarget(VocabEntry entry) =>
    entry.isLanguage ? entry.german : entry.answer;

/// Was als Aufgabe oben steht — das Gegenstück zu [typedTarget].
String typedPrompt(VocabEntry entry) =>
    entry.isLanguage ? entry.arabic : entry.prompt;
