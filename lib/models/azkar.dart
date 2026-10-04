import 'package:flutter/foundation.dart';

/// Morgen oder Abend.
///
/// Die beiden Fenster richten sich nach den Gebetszeiten: die Morgen-Azkar
/// nach Fajr, die Abend-Azkar nach ʿAsr. Siehe `lib/state/prayer_times.dart`.
enum AzkarTime {
  morgens('morgens', 'Morgen-Azkar'),
  abends('abends', 'Abend-Azkar');

  const AzkarTime(this.id, this.label);

  final String id;
  final String label;

  static AzkarTime? byId(String id) {
    for (final AzkarTime t in values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Wie viel man sich vornimmt.
///
/// **Eine Einstellung, keine Mauer.** Auf [leicht] stehen die übrigen Azkar
/// weiter unten und lassen sich antippen — wer an einem guten Tag mehr
/// schafft, soll nicht erst in die Einstellungen müssen.
enum AzkarLevel {
  leicht('leicht', 'Leicht', 'Die wichtigsten — gut zwei Minuten'),
  voll('voll', 'Voll', 'Der Regelfall — gut fünf Minuten'),
  vollstaendig('vollstaendig', 'Vollständig', 'Wenn Ruhe da ist — gut zwölf Minuten');

  const AzkarLevel(this.id, this.label, this.hint);

  final String id;
  final String label;
  final String hint;

  /// Enthält diese Stufe alles von [andere]?
  bool umfasst(AzkarLevel andere) => index >= andere.index;

  static AzkarLevel? byId(String id) {
    for (final AzkarLevel l in values) {
      if (l.id == id) return l;
    }
    return null;
  }
}

/// Ein einzelnes Gedenken.
@immutable
class Dhikr {
  const Dhikr({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.german,
    required this.source,
    required this.times,
    required this.level,
    this.count = 1,
    this.note,
  });

  /// Stabile Kennung — sie steht im Tagesstand und darf sich nicht ändern,
  /// sonst gilt ein abgehaktes Dhikr plötzlich als offen.
  final String id;

  final String arabic;
  final String transliteration;

  /// Eine schlichte Verständnishilfe auf Deutsch, keine anerkannte
  /// Übersetzung — wie beim Quran-Teil der App.
  final String german;

  /// Woher es stammt: Quran-Stelle oder Hadith-Sammlung mit Nummer.
  final String source;

  /// Wie oft es gesprochen wird.
  final int count;

  /// Morgens, abends oder beides.
  final Set<AzkarTime> times;

  /// Ab welcher Stufe es dabei ist.
  final AzkarLevel level;

  /// Ein Satz Zusammenhang, wo er hilft.
  final String? note;

  bool giltFuer(AzkarTime time) => times.contains(time);
}
