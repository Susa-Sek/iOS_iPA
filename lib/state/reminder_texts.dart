import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';
import 'duel.dart' show stableMix;
import 'word_progress.dart';

/// Wann am Tag eine Erinnerung kommt.
///
/// Die drei **Lern**-Anstöße haben verschiedene Aufgaben: Der Morgen nimmt
/// etwas mit, der Mittag nennt den Stand, der Abend ist der Termin mit
/// Gewicht — dort steht die Serie auf dem Spiel.
///
/// Dazu zwei **Azkar**-Anstöße. Die sind anders: Ihre Zeit steht nicht in
/// einer Einstellung, sondern kommt aus den Gebetszeiten (nach Fajr und nach
/// ʿAsr, siehe `lib/state/prayer_times.dart`), und sie schweigen, sobald die
/// Azkar des Tages gesprochen sind.
enum ReminderSlot {
  morgens('morgens'),
  mittags('mittags'),
  abends('abends'),
  azkarMorgens('azkar-morgens'),
  azkarAbends('azkar-abends');

  const ReminderSlot(this.id);

  final String id;

  /// Azkar oder Lernen? Davon hängt ab, woher die Zeit kommt und welcher
  /// Text erscheint.
  bool get istAzkar =>
      this == ReminderSlot.azkarMorgens || this == ReminderSlot.azkarAbends;
}

/// Was der Lernkern zur Erinnerung beisteuert.
///
/// Bewusst nur Zahlen und ein Wort statt einer Referenz auf den Lernstand:
/// So bleibt [buildReminderText] eine reine Funktion, die ein Test ohne Gerät
/// und ohne Speicher prüfen kann.
@immutable
class ReminderFacts {
  const ReminderFacts({
    this.streak = 0,
    this.freezes = 0,
    this.blockNumber = 1,
    this.blockOpen = 0,
    this.repetitionsDue = 0,
    this.goalRemaining = 0,
    this.azkarStreakMorgens = 0,
    this.azkarStreakAbends = 0,
    this.woerter = const <VocabEntry>[],
  });

  /// Wie viele Tage die Serie schon läuft.
  final int streak;

  /// Jokertage im Vorrat.
  final int freezes;

  /// Der laufende Block und wie viele seiner Wörter noch nicht sitzen.
  final int blockNumber;
  final int blockOpen;

  /// **Angefangene** Einträge, deren Termin gekommen ist — nicht `dueCount`.
  ///
  /// Der Unterschied ist der Grund, warum in der Abendmeldung früher eine
  /// unerreichbare Zahl stand: `dueEntries` hält auch ein nie angesehenes
  /// Wort für fällig, über beide Fächer also fast den ganzen Bestand.
  final int repetitionsDue;

  /// Wie viele Antworten heute noch bis zum Tagesziel fehlen.
  final int goalRemaining;

  /// Tage am Stück bei den Azkar — getrennt nach Morgen und Abend, und
  /// getrennt von der Lernserie.
  final int azkarStreakMorgens;
  final int azkarStreakAbends;

  /// Wörter aus dem Arbeitsvorrat — welche, die gerade wirklich dran sind.
  ///
  /// Eine Liste und nicht ein Wort: Der Plan reicht vierzehn Tage, und jeder
  /// Morgen soll ein anderes Wort zeigen.
  final List<VocabEntry> woerter;

  /// Derselbe Stand ohne die Zahlen.
  ///
  /// Für die Tage nach heute: Wie viele Wiederholungen dann fällig sind, weiß
  /// heute niemand — eine Zahl, die bis dahin falsch wird, ist schlimmer als
  /// keine. Die Wörter bleiben, die sind in drei Tagen noch dieselben.
  ReminderFacts get ohneZahlen => ReminderFacts(woerter: woerter);

  int azkarStreak(ReminderSlot slot) => slot == ReminderSlot.azkarMorgens
      ? azkarStreakMorgens
      : azkarStreakAbends;
}

/// Titel und Text einer Benachrichtigung.
@immutable
class ReminderText {
  const ReminderText(this.title, this.body);

  final String title;
  final String body;

  @override
  String toString() => '$title — $body';
}

/// Der Text für einen Tag und einen Anstoß.
///
/// **Warum das eine eigene Funktion ist.** Vorher stand in jeder Meldung ab
/// morgen derselbe Satz, vierzehn Tage lang. So etwas liest man nach drei
/// Tagen nicht mehr — die Erinnerung wird zur Tapete, und genau daran ist sie
/// gescheitert.
///
/// Der Zufall hängt an Tag und Anstoß, wie bei den Tagesaufgaben
/// (`buildQuests`): Derselbe Tag ergibt denselben Text, ohne dass dafür etwas
/// gespeichert werden müsste.
///
/// **Eine Regel über allem:** keine Zahl, die nicht stimmt. Ist nichts fällig,
/// steht nichts von Wiederholungen da; gibt es keine Serie, wird auch keine
/// beschworen.
ReminderText buildReminderText({
  required DateTime day,
  required ReminderSlot slot,
  required ReminderFacts facts,
}) {
  // Tag und Anstoß **durchgerührt**, nicht addiert: Bei benachbarten
  // Startwerten liefert Darts Zufall oft denselben ersten Griff — dann fällt
  // an drei Tagen hintereinander derselbe Satz, genau das, was hier aufhören
  // soll. `stableMix` (FNV-1a, aus dem Duell-Code) trennt sie sauber.
  final Random random = Random(stableMix(<int>[
    dayOf(day).millisecondsSinceEpoch ~/ 86400000,
    slot.index,
  ]));

  // Die Azkar haben eigene Texte: Sie rufen zu etwas anderem als zum Lernen,
  // und ein Satz über fällige Vokabeln wäre hier schlicht falsch.
  if (slot.istAzkar) {
    final List<ReminderText> azkar = _azkar(slot, facts);
    return azkar[random.nextInt(azkar.length)];
  }

  // Der Abend gehört der Serie, sobald etwas auf dem Spiel steht. Das ist der
  // einzige Vorrang: Wer seit Tagen dran ist, soll es am Abend lesen und
  // nicht dem Zufall überlassen.
  if (slot == ReminderSlot.abends && _serieInGefahr(facts)) {
    final List<ReminderText> serie = _serie(facts);
    return serie[random.nextInt(serie.length)];
  }

  final ReminderText allgemein = _pool[random.nextInt(_pool.length)];
  final List<ReminderText> passend = _passend(slot, facts, random);
  if (passend.isEmpty) return allgemein;

  // Der allgemeine Satz bleibt immer im Topf, sonst käme bei gleichbleibendem
  // Stand tagelang dieselbe Zahl.
  final List<ReminderText> alle = <ReminderText>[...passend, allgemein];
  return alle[random.nextInt(alle.length)];
}

bool _serieInGefahr(ReminderFacts facts) =>
    facts.streak >= 3 && facts.goalRemaining > 0;

List<ReminderText> _serie(ReminderFacts facts) => <ReminderText>[
      ReminderText('Tag ${facts.streak}', 'Bis Mitternacht zählt heute noch.'),
      ReminderText('Deine Serie: ${facts.streak} Tage',
          'Heute steht noch nichts drin — eine Runde hält sie.'),
      if (facts.freezes > 0)
        ReminderText('Tag ${facts.streak}',
            'Ein Jokertag würde greifen. Schöner ist es ohne.')
      else
        ReminderText('${facts.streak} Tage am Stück',
            'Wäre schade, ausgerechnet heute aufzuhören.'),
    ];

/// Die Sätze, die zu diesem Anstoß passen — je nach Tageszeit in anderer
/// Reihenfolge, aber nie erfunden.
List<ReminderText> _passend(
    ReminderSlot slot, ReminderFacts facts, Random random) {
  final List<ReminderText> wort = _wortDesTages(facts, random);
  final List<ReminderText> stand = _stand(facts);
  return switch (slot) {
    ReminderSlot.morgens => <ReminderText>[...wort, ...stand],
    ReminderSlot.mittags => <ReminderText>[...stand, ...wort],
    ReminderSlot.abends => <ReminderText>[...stand, ...wort],
    // Die Azkar kommen hier nie an — sie werden oben abgefangen. Der Zweig
    // steht da, damit ein neuer Anstoß den Übersetzer alarmiert statt still
    // in den falschen Text zu laufen.
    ReminderSlot.azkarMorgens || ReminderSlot.azkarAbends =>
      const <ReminderText>[],
  };
}

/// Etwas gelernt, ohne die App zu öffnen.
List<ReminderText> _wortDesTages(ReminderFacts facts, Random random) {
  if (facts.woerter.isEmpty) return const <ReminderText>[];
  final VocabEntry entry = facts.woerter[random.nextInt(facts.woerter.length)];
  final String rueckseite = entry.isLanguage
      ? (entry.transliteration.isEmpty ? entry.arabic : entry.transliteration)
      : entry.answer;
  if (rueckseite.isEmpty) return const <ReminderText>[];
  return <ReminderText>[
    ReminderText('Ein Wort für unterwegs', '${entry.german} — $rueckseite'),
  ];
}

/// Was wirklich ansteht — und nur das.
List<ReminderText> _stand(ReminderFacts facts) => <ReminderText>[
      if (facts.blockOpen > 0)
        ReminderText(
          'Block ${facts.blockNumber}',
          'Noch ${facts.blockOpen} ${facts.blockOpen == 1 ? "Wort" : "Wörter"}, '
              'dann ist er durch.',
        ),
      if (facts.repetitionsDue > 0)
        ReminderText(
          'Wiederholungen warten',
          '${facts.repetitionsDue} '
              '${facts.repetitionsDue == 1 ? "Wort" : "Wörter"} '
              'sind heute dran — ein paar Minuten reichen.',
        ),
      if (facts.goalRemaining > 0 && facts.goalRemaining <= 5)
        ReminderText(
          'Fast geschafft',
          'Noch ${facts.goalRemaining} '
              '${facts.goalRemaining == 1 ? "Antwort" : "Antworten"} '
              'bis zum Tagesziel.',
        ),
    ];

/// Die Texte der Azkar-Anstöße.
///
/// Ein anderer Ton als bei den Lern-Anstößen: kein Antreiben, kein Zählen
/// von Wörtern. Die Serie kommt nur vor, wenn sie schon eine Weile läuft —
/// und als Feststellung, nicht als Druckmittel.
List<ReminderText> _azkar(ReminderSlot slot, ReminderFacts facts) {
  final bool morgens = slot == ReminderSlot.azkarMorgens;
  final String titel = morgens ? 'Morgen-Azkar' : 'Abend-Azkar';
  final int serie = facts.azkarStreak(slot);
  return <ReminderText>[
    ReminderText(titel, morgens
        ? 'Die Zeit ist da — ein paar Minuten vor dem Tag.'
        : 'Die Zeit ist da — ein paar Minuten vor dem Abend.'),
    ReminderText(titel, 'Jetzt wäre die Zeit dafür.'),
    if (serie >= 3)
      ReminderText('$titel · Tag $serie', 'Heute wieder?')
    else
      ReminderText(titel, morgens
          ? 'Zum Anfangen reicht die leichte Stufe.'
          : 'Auch kurz ist gesprochen.'),
  ];
}

/// Der Rückfall, wenn nichts Konkretes anliegt — und der Grund, warum sich
/// die Meldung auch bei gleichbleibendem Stand nicht abnutzt.
const List<ReminderText> _pool = <ReminderText>[
  ReminderText('Zeit für ein paar Wörter', 'Fünf Minuten reichen für eine Runde.'),
  ReminderText('Kurz aufmachen?',
      'Eine Karteikarte ist schneller durch als dieser Satz.'),
  ReminderText('Heute schon klüger?',
      'Ein Block wartet — mehr braucht es heute nicht.'),
  ReminderText('Zwei Minuten', 'Eine Kurzrunde geht auch im Stehen.'),
  ReminderText('Dein Kopf hat Platz', 'Ein paar Wörter, dann ist gut.'),
  ReminderText('Kleine Portion',
      'Jeden Tag ein bisschen — das ist der ganze Trick.'),
  ReminderText('Kurz üben',
      'Lieber fünf Minuten heute als eine Stunde am Sonntag.'),
  ReminderText('Nur eine Runde', 'Du musst nicht viel machen. Nur nicht nichts.'),
  ReminderText('Ein Moment für dich',
      'Vokabeln sind eine ruhige Sache. Gute Zeit dafür.'),
  ReminderText('Anfangen ist das Schwerste',
      'Aufmachen reicht — der Rest läuft von allein.'),
];
