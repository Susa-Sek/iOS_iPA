import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

import 'word_progress.dart';

/// Was an einem Tag zu tun ist.
///
/// Getrennt in zwei Sorten, und das ist der Grund, warum ein Tag sich machbar
/// anfühlt: Eine Aufgabe **zählt** (Fragen beantworten), zwei sind **getan
/// oder nicht** (eine Lektion, ein Thema, eine fehlerfreie Runde). Drei
/// zählende Aufgaben wären dreimal dasselbe; drei ganze Übungen wären zu
/// viel für zwischendurch.
enum QuestKind {
  /// Zählt mit: Fragen beantwortet.
  antworten,

  /// Zählt mit: davon richtig.
  richtige,

  /// Getan oder nicht: eine Runde ohne einen Fehler.
  fehlerfrei,

  /// Getan oder nicht: eine Lektion im Wissen.
  lektion,

  /// Getan oder nicht: ein Thema durchgewischt.
  feed,

  /// Getan oder nicht: eine Kurzrunde in Arabisch.
  kurzrunde;

  /// Der Schlüssel im Speicher — bleibt stabil, auch wenn der Text sich
  /// ändert.
  String get id => name;

  static QuestKind? byId(String? id) {
    for (final QuestKind k in QuestKind.values) {
      if (k.id == id) return k;
    }
    return null;
  }

  bool get zaehlt => this == QuestKind.antworten || this == QuestKind.richtige;

  IconData get icon => switch (this) {
        QuestKind.antworten => Icons.touch_app_outlined,
        QuestKind.richtige => Icons.check_circle_outline,
        QuestKind.fehlerfrei => Icons.auto_awesome_outlined,
        QuestKind.lektion => Icons.menu_book_outlined,
        QuestKind.feed => Icons.swipe_up_alt_outlined,
        QuestKind.kurzrunde => Icons.play_arrow_rounded,
      };
}

/// Eine Tagesaufgabe: was zu tun ist, wie viel davon und was es bringt.
@immutable
class Quest {
  const Quest({
    required this.kind,
    required this.target,
    required this.xp,
    required this.label,
  });

  final QuestKind kind;
  final int target;

  /// Punkte, sobald sie erledigt ist.
  final int xp;

  /// Was dasteht — mit der Zahl darin, weil „Fragen beantworten" ohne sie
  /// nichts sagt.
  final String label;

  bool isDone(int stand) => stand >= target;

  double ratio(int stand) =>
      target == 0 ? 1 : (stand / target).clamp(0, 1).toDouble();

  @override
  String toString() => '${kind.id} ×$target';
}

/// Wie viele Aufgaben ein Tag hat.
const int kQuestsPerDay = 3;

/// Die Aufgaben eines Tages.
///
/// Reine Funktion wie `buildShorts` und `buildSession` — erst prüfbar, dann
/// ein Bildschirm.
///
/// **Aus dem Datum abgeleitet, nicht gewürfelt.** Ein Neustart der App darf
/// die Aufgaben nicht neu mischen: Wer zwei davon geschafft hat und die App
/// schließt, käme sonst zu drei neuen zurück.
///
/// Angeboten wird nur, wofür es Inhalt gibt: ohne Wissen keine Lektion, ohne
/// Arabisch keine Kurzrunde.
List<Quest> buildQuests({
  required DateTime day,
  required int dailyGoal,
  required bool hatArabisch,
  required bool hatWissen,
}) {
  // Der Tag selbst ist der Zufall — dieselbe Zahl ergibt dieselben Aufgaben.
  final Random random = Random(dayOf(day).millisecondsSinceEpoch ~/ 86400000);

  final List<QuestKind> zaehlend = <QuestKind>[
    QuestKind.antworten,
    QuestKind.richtige,
  ]..shuffle(random);

  final List<QuestKind> taetig = <QuestKind>[
    QuestKind.fehlerfrei,
    if (hatWissen) QuestKind.lektion,
    if (hatWissen) QuestKind.feed,
    if (hatArabisch) QuestKind.kurzrunde,
  ]..shuffle(random);

  final List<QuestKind> gewaehlt = <QuestKind>[
    zaehlend.first,
    ...taetig.take(kQuestsPerDay - 1),
  ];
  // Gibt es zu wenige Übungen, füllt die zweite zählende Aufgabe auf.
  for (final QuestKind k in zaehlend) {
    if (gewaehlt.length >= kQuestsPerDay) break;
    if (!gewaehlt.contains(k)) gewaehlt.add(k);
  }

  return <Quest>[
    for (final QuestKind kind in gewaehlt) _quest(kind, dailyGoal),
  ];
}

Quest _quest(QuestKind kind, int dailyGoal) {
  final int ziel = dailyGoal.clamp(1, 200);
  return switch (kind) {
    QuestKind.antworten => Quest(
        kind: kind,
        target: (ziel * 1.5).round(),
        xp: 20,
        label: '${(ziel * 1.5).round()} Fragen beantworten',
      ),
    QuestKind.richtige => Quest(
        kind: kind,
        target: ziel,
        xp: 20,
        label: '$ziel Fragen richtig beantworten',
      ),
    QuestKind.fehlerfrei => const Quest(
        kind: QuestKind.fehlerfrei,
        target: 1,
        xp: 30,
        label: 'Eine Runde ohne einen Fehler',
      ),
    QuestKind.lektion => const Quest(
        kind: QuestKind.lektion,
        target: 1,
        xp: 30,
        label: 'Eine Lektion durcharbeiten',
      ),
    QuestKind.feed => const Quest(
        kind: QuestKind.feed,
        target: 1,
        xp: 30,
        label: 'Ein Thema durchwischen',
      ),
    QuestKind.kurzrunde => const Quest(
        kind: QuestKind.kurzrunde,
        target: 1,
        xp: 30,
        label: 'Eine Kurzrunde spielen',
      ),
  };
}
