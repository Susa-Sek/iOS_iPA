import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';
import 'typing_check.dart';

/// Die Übungsarten, die in einer Kurzrunde vorkommen können.
enum ExerciseKind {
  karteikarten,
  quiz,
  zuordnen,
  wortBauen,
  tippen;

  String get label => switch (this) {
        ExerciseKind.karteikarten => 'Karteikarten',
        ExerciseKind.quiz => 'Quiz',
        ExerciseKind.zuordnen => 'Zuordnen',
        ExerciseKind.wortBauen => 'Wort bauen',
        ExerciseKind.tippen => 'Tippen',
      };

  /// Wie viele Aufgaben ein Block dieser Art hat.
  int get itemsPerBlock => switch (this) {
        ExerciseKind.karteikarten => 3,
        ExerciseKind.quiz => 3,
        // Zuordnen zeigt Paare nebeneinander; weniger als vier lohnt nicht.
        ExerciseKind.zuordnen => 4,
        ExerciseKind.wortBauen => 2,
        ExerciseKind.tippen => 2,
      };

  /// Wie viele Einträge der Vorrat mindestens hergeben muss.
  int get minimumPool => switch (this) {
        ExerciseKind.quiz => 4,
        ExerciseKind.zuordnen => 4,
        _ => itemsPerBlock,
      };
}

/// Ein Abschnitt einer Kurzrunde: eine Übungsart mit ihren Aufgaben.
@immutable
class SessionBlock {
  const SessionBlock(this.kind, this.entries);

  final ExerciseKind kind;
  final List<VocabEntry> entries;

  int get length => entries.length;

  @override
  String toString() => '${kind.label} (${entries.length})';
}

/// Wie viele Blöcke eine Kurzrunde hat.
const int kBlocksPerSession = 3;

/// Ob ein Eintrag sich für eine Übungsart eignet.
///
/// Die Regeln stehen dort, wo sie herkommen: `isTypeable` beim Tippen, die
/// Längengrenze beim Zuordnen, arabische Buchstaben beim Wortbauen. Hier
/// werden sie nur zusammengeführt — die Bildschirme reichen ihre eigene
/// Prüfung durch, damit es keine zweite Wahrheit gibt.
typedef Suitability = bool Function(VocabEntry entry);

/// Baut eine Kurzrunde: wenige Aufgaben, mehrere Arten, nie zweimal
/// dieselbe hintereinander.
///
/// Ohne Widgets und ohne Kontext, damit sie prüfbar ist — wie
/// `buildQuizRound`.
List<SessionBlock> buildSession({
  required List<VocabEntry> pool,
  required Random random,
  required Map<ExerciseKind, Suitability> suitability,
  int blocks = kBlocksPerSession,
}) {
  if (pool.isEmpty || blocks <= 0) return const <SessionBlock>[];

  // Für jede Art: Welche Einträge kämen überhaupt in Frage?
  final Map<ExerciseKind, List<VocabEntry>> moeglich =
      <ExerciseKind, List<VocabEntry>>{};
  for (final ExerciseKind kind in ExerciseKind.values) {
    final Suitability passt = suitability[kind] ?? _immer;
    final List<VocabEntry> passend = pool.where(passt).toList();
    if (passend.length >= kind.minimumPool) moeglich[kind] = passend;
  }
  if (moeglich.isEmpty) return const <SessionBlock>[];

  final List<SessionBlock> runde = <SessionBlock>[];
  final Set<String> schonBenutzt = <String>{};
  ExerciseKind? zuletzt;

  for (int i = 0; i < blocks; i++) {
    // Erst die Arten, die noch nicht dran waren: Abwechslung ist der Zweck.
    final List<ExerciseKind> frisch = <ExerciseKind>[
      for (final ExerciseKind k in moeglich.keys)
        if (k != zuletzt && !runde.any((SessionBlock b) => b.kind == k)) k,
    ];
    final List<ExerciseKind> ersatz = <ExerciseKind>[
      for (final ExerciseKind k in moeglich.keys)
        if (k != zuletzt) k,
    ];
    final List<ExerciseKind> auswahl = frisch.isNotEmpty ? frisch : ersatz;
    if (auswahl.isEmpty) break;

    final ExerciseKind kind = auswahl[random.nextInt(auswahl.length)];
    final List<VocabEntry> block = _waehle(
      moeglich[kind]!,
      kind.itemsPerBlock,
      schonBenutzt,
      random,
    );
    if (block.isEmpty) break;

    runde.add(SessionBlock(kind, block));
    schonBenutzt.addAll(block.map((VocabEntry e) => e.id));
    zuletzt = kind;
  }

  return runde;
}

bool _immer(VocabEntry entry) => true;

/// Nimmt Einträge, die in dieser Runde noch nicht vorkamen — und füllt erst
/// auf, wenn der Vorrat zu klein ist.
List<VocabEntry> _waehle(
  List<VocabEntry> kandidaten,
  int anzahl,
  Set<String> schonBenutzt,
  Random random,
) {
  final List<VocabEntry> frisch = <VocabEntry>[
    for (final VocabEntry e in kandidaten)
      if (!schonBenutzt.contains(e.id)) e,
  ];
  // Die Reihenfolge des Vorrats ist schon die Übungsreihenfolge (fällige und
  // schwache zuerst) — sie bleibt erhalten, gemischt wird nur bei Bedarf.
  final List<VocabEntry> quelle =
      frisch.length >= anzahl ? frisch : (List<VocabEntry>.of(kandidaten)..shuffle(random));
  return quelle.take(min(anzahl, quelle.length)).toList();
}

/// Wie viele Aufgaben eine Runde insgesamt hat.
int sessionLength(List<SessionBlock> blocks) =>
    blocks.fold(0, (int summe, SessionBlock b) => summe + b.length);

/// Die übliche Eignungstabelle der App.
///
/// Karteikarten und Quiz gehen mit allem; die drei anderen bringen ihre
/// eigenen Bedingungen mit und werden von den Bildschirmen durchgereicht.
Map<ExerciseKind, Suitability> suitabilityFor({
  required Suitability wortBauen,
  required Suitability zuordnen,
}) =>
    <ExerciseKind, Suitability>{
      ExerciseKind.karteikarten: _immer,
      ExerciseKind.quiz: _immer,
      ExerciseKind.zuordnen: zuordnen,
      ExerciseKind.wortBauen: wortBauen,
      ExerciseKind.tippen: isTypeable,
    };
