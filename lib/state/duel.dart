import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';
import 'quiz_builder.dart';

/// Ein Duell: dieselben Fragen auf zwei Telefonen, ohne Server.
///
/// **Warum ein Code und kein Konto.** Die App hat keinen Server, keine
/// Anmeldung und keine Daten, die das Gerät verlassen. Ein Duell braucht das
/// auch nicht: Wenn beide Seiten aus derselben Zahl dieselben Fragen bauen,
/// genügt es, diese Zahl zu verschicken. Was durch WhatsApp geht, ist ein
/// kurzer Text — mehr nicht, und man sieht selbst, was man verschickt.
@immutable
class Duel {
  const Duel({
    required this.topicId,
    required this.seed,
    required this.count,
    required this.fingerprint,
  });

  /// Das Thema, aus dem gefragt wird — leer heißt „gemischt".
  final String topicId;

  /// Die Zahl, aus der beide Seiten dieselbe Runde bauen.
  final int seed;

  /// Wie viele Fragen.
  final int count;

  /// Kurzsumme über die Fragen des Themas.
  ///
  /// Hat der Freund eine andere App-Version mit anderen Fragen, passt sie
  /// nicht — und das soll dastehen, statt stillschweigend andere Fragen zu
  /// stellen und die Ergebnisse trotzdem zu vergleichen.
  final int fingerprint;

  /// Der stabile Fingerabdruck des Themas — zwei Byte, damit sich nicht
  /// zwei Themen dieselbe Zahl teilen.
  int get topicHash => stableHash(topicId) & 0xFFFF;

  /// Eine kurze Kennung dieses Duells — sie steht im Ergebnis-Code und
  /// ordnet ihn der richtigen Runde zu.
  int get id =>
      stableMix(<int>[seed, count, fingerprint, topicHash]) & 0xFFFF;

  @override
  bool operator ==(Object other) =>
      other is Duel &&
      other.topicId == topicId &&
      other.seed == seed &&
      other.count == count &&
      other.fingerprint == fingerprint;

  @override
  int get hashCode => Object.hash(topicId, seed, count, fingerprint);

  @override
  String toString() => 'Duell $topicId ×$count (Seed $seed)';
}

/// Das Ergebnis einer Seite.
@immutable
class DuelResult {
  const DuelResult({
    required this.duelId,
    required this.correct,
    required this.total,
  });

  /// [Duel.id] der Runde, zu der das Ergebnis gehört.
  final int duelId;
  final int correct;
  final int total;

  @override
  String toString() => '$correct von $total';
}

/// Wie viele Fragen ein Duell hat.
const int kDuelQuestions = 10;

/// Das Alphabet der Codes.
///
/// Crockford-Base32: ohne I, L, O und U. Die ersten drei verwechselt man
/// beim Abtippen mit 1 und 0, das U mit V — und ein Code, den man einmal
/// falsch abschreibt, gibt eine andere Runde.
const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// Version des Codeformats. Ändert sich der Aufbau, erkennt eine ältere App
/// das am ersten Zeichen, statt Unsinn zu lesen.
const int _version = 1;

/// Baut ein neues Duell für ein Thema.
Duel newDuel({
  required String topicId,
  required List<VocabEntry> pool,
  required Random random,
  int count = kDuelQuestions,
}) =>
    Duel(
      topicId: topicId,
      // 32 Bit — mehr passt nicht in den Code, und weniger wäre ratbar.
      seed: random.nextInt(0xFFFFFFFF),
      count: min(count, pool.length).clamp(1, 63),
      fingerprint: fingerprintOf(pool),
    );

/// Baut die Runde eines Duells — auf beiden Telefonen dieselbe.
///
/// **Das ist der ganze Trick.** `buildQuizRound` mischt die vier Antworten
/// bereits mit dem übergebenen Zufall; bekommt es auf beiden Seiten
/// denselben Seed und denselben Vorrat, kommen dieselben Fragen in derselben
/// Reihenfolge mit denselben Antworten an derselben Stelle heraus. Es
/// braucht dafür nichts Neues — nur, dass nichts anderes dazwischenfunkt.
///
/// Deshalb wird der Vorrat vorher **nach Kennung sortiert**: Die Reihenfolge
/// im Speicher darf sich ändern (eine gemerkte Karte, ein umsortiertes
/// Thema), die Runde nicht.
List<QuizQuestion> buildDuelRound({
  required Duel duel,
  required List<VocabEntry> pool,
}) {
  final List<VocabEntry> sortiert = List<VocabEntry>.of(pool)
    ..sort((VocabEntry a, VocabEntry b) => a.id.compareTo(b.id));
  final List<VocabEntry> gezogen = List<VocabEntry>.of(sortiert)
    ..shuffle(Random(duel.seed));

  return buildQuizRound(
    ordered: gezogen.take(duel.count).toList(),
    // Auch der Vorrat für aufgefüllte Ablenker muss auf beiden Seiten
    // gleich sein — sonst stünde dort einmal „Donau" und einmal „Rhein".
    pool: sortiert,
    direction: QuizDirection.arabicToGerman,
    random: Random(duel.seed),
    count: duel.count,
  );
}

/// Die Kurzsumme über einen Fragenvorrat.
///
/// Sie hängt an den Kennungen der Einträge und **nicht** an ihrer
/// Reihenfolge im Speicher: Ein umsortiertes Thema ist noch dasselbe Thema.
int fingerprintOf(List<VocabEntry> pool) {
  final List<String> ids = <String>[for (final VocabEntry e in pool) e.id]
    ..sort();
  return stableMix(<int>[for (final String id in ids) stableHash(id)]) &
      0xFFFF;
}

/// Der Code, den man verschickt: „TK-4G7Q-M2XP-RB91-KTZ4".
String encodeDuel(Duel duel) {
  final List<int> bytes = <int>[
    _version,
    (duel.fingerprint >> 8) & 0xFF,
    duel.fingerprint & 0xFF,
    (duel.topicHash >> 8) & 0xFF,
    duel.topicHash & 0xFF,
    (duel.seed >> 24) & 0xFF,
    (duel.seed >> 16) & 0xFF,
    (duel.seed >> 8) & 0xFF,
    duel.seed & 0xFF,
    duel.count & 0x3F,
  ];
  final String roh = _base32(bytes);
  return 'TK-${roh.substring(0, 4)}-${roh.substring(4, 8)}-'
      '${roh.substring(8, 12)}-${roh.substring(12)}';
}

/// Liest einen Duell-Code aus beliebigem Text.
///
/// Aus **beliebigem** Text, nicht nur aus einer sauberen Zeile: Man fügt die
/// ganze Nachricht ein („Schaffst du das? TK-4G7QM-…"), und die App sucht
/// sich den Code heraus. Alles andere wäre eine Fleißaufgabe für den, der
/// mitspielen will.
///
/// Gibt `null` zurück, wenn nichts Brauchbares drinsteht — ein verdrehtes
/// Zeichen ergibt keine andere Runde, sondern gar keine.
Duel? decodeDuel(String text, {required String? Function(int) topicByHash}) {
  final RegExpMatch? treffer =
      RegExp(r'TK-([0-9A-Za-z](?:[0-9A-Za-z-]{16,24}))').firstMatch(text);
  if (treffer == null) return null;

  final String roh = treffer.group(1)!.replaceAll('-', '').toUpperCase();
  if (roh.length != 16) return null;

  final List<int>? bytes = _unbase32(roh, 10);
  if (bytes == null || bytes[0] != _version) return null;

  final int themenSumme = (bytes[3] << 8) | bytes[4];
  final String? thema = topicByHash(themenSumme);
  // Kein Thema mit dieser Summe: Der Code kommt aus einer App mit anderem
  // Bestand. Lieber nichts als die falsche Runde.
  if (thema == null) return null;

  final int anzahl = bytes[9] & 0x3F;
  if (anzahl == 0) return null;

  return Duel(
    fingerprint: (bytes[1] << 8) | bytes[2],
    topicId: thema,
    seed: (bytes[5] << 24) | (bytes[6] << 16) | (bytes[7] << 8) | bytes[8],
    count: anzahl,
  );
}

/// Der Code, den man zurückschickt: „TKE-3F9A2K7M".
String encodeResult(DuelResult result) {
  final List<int> bytes = <int>[
    _version,
    (result.duelId >> 8) & 0xFF,
    result.duelId & 0xFF,
    result.correct.clamp(0, 255),
    result.total.clamp(0, 255),
  ];
  return 'TKE-${_base32(bytes)}';
}

/// Liest einen Ergebnis-Code aus beliebigem Text.
DuelResult? decodeResult(String text) {
  final RegExpMatch? treffer =
      RegExp(r'TKE-([0-9A-Za-z]{8})').firstMatch(text);
  if (treffer == null) return null;

  final List<int>? bytes = _unbase32(treffer.group(1)!.toUpperCase(), 5);
  if (bytes == null || bytes[0] != _version) return null;

  final int gesamt = bytes[4];
  final int richtig = bytes[3];
  // Mehr richtig als gestellt gibt es nicht — dann ist der Code kaputt.
  if (gesamt == 0 || richtig > gesamt) return null;

  return DuelResult(
    duelId: (bytes[1] << 8) | bytes[2],
    correct: richtig,
    total: gesamt,
  );
}

// ---- Base32 -------------------------------------------------------------

/// Bytes zu Zeichen, fünf Bit auf einmal.
String _base32(List<int> bytes) {
  final StringBuffer out = StringBuffer();
  int puffer = 0;
  int bits = 0;
  for (final int b in bytes) {
    puffer = (puffer << 8) | b;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out.write(_alphabet[(puffer >> bits) & 0x1F]);
    }
  }
  if (bits > 0) out.write(_alphabet[(puffer << (5 - bits)) & 0x1F]);
  return out.toString();
}

/// Zurück zu Bytes. `null`, sobald ein Zeichen nicht ins Alphabet gehört.
List<int>? _unbase32(String text, int erwartet) {
  int puffer = 0;
  int bits = 0;
  final List<int> out = <int>[];
  for (final int einheit in text.codeUnits) {
    final int wert = _alphabet.indexOf(String.fromCharCode(einheit));
    if (wert < 0) return null;
    puffer = (puffer << 5) | wert;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      out.add((puffer >> bits) & 0xFF);
    }
  }
  return out.length < erwartet ? null : out.sublist(0, erwartet);
}

/// Eine einfache, **stabile** Mischung.
///
/// Bewusst nicht `Object.hashCode`: Der ist von Lauf zu Lauf und von
/// Dart-Version zu Dart-Version nicht garantiert derselbe. Für ein Duell auf
/// zwei Telefonen wäre das tödlich — beide müssen aus demselben Code
/// dieselben Fragen bauen, sonst vergleicht man Ergebnisse zu
/// verschiedenen Runden.
///
/// Kein kryptografischer Hash: Hier wird nichts geschützt, sondern nur
/// festgestellt, ob zwei Geräte denselben Fragenbestand meinen.
int stableMix(List<int> werte) {
  int h = 0x811C9DC5;
  for (final int w in werte) {
    h ^= w & 0xFFFFFFFF;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// Die stabile Summe einer Zeichenkette (FNV-1a über die Zeichen).
int stableHash(String text) => stableMix(text.codeUnits);
