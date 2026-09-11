import '../models/daily_item.dart';
import '../models/vocabulary.dart';

/// Wie viele Ereignisse aus „Was geschah heute" am Tag mitgenommen werden.
///
/// Eines. Wikipedia listet für jedes Datum ein Dutzend — alle einzusammeln
/// wäre keine Abwechslung, sondern eine Hausaufgabe, die täglich wächst.
const int kEventsPerDay = 1;

/// Was ein Tag an Lernkarten hergibt.
///
/// Reine Funktion wie `buildShorts`, `buildQuests` und `buildDuelRound` —
/// erst prüfbar, dann eingebaut.
///
/// **Der Kern liegt woanders und wird hier nur endlich benutzt.**
/// `DailyItem.toCard()` macht seit dem Bereich „Heute" aus dem Artikel des
/// Tages eine Begriffskarte und aus einem Ereignis eine Jahresfrage mit drei
/// plausiblen Falschantworten. Bisher musste man jeden Fund von Hand auf
/// „Als Karte merken" tippen; das tut niemand täglich. Hier entsteht die
/// Tagesration, die von selbst kommt.
///
/// Nachrichten fallen weg — `canRemember` sagt das schon, und der Grund
/// steht dort: Sie wären in einer Wiederholung nach drei Wochen überholt.
List<VocabEntry> harvestDaily(
  DailyFeed feed, {
  int maxEvents = kEventsPerDay,
  int? currentYear,
}) {
  final List<VocabEntry> ernte = <VocabEntry>[];
  final Set<String> gesehen = <String>{};

  void nimm(DailyItem? item) {
    if (item == null) return;
    final VocabEntry? karte = item.toCard(currentYear: currentYear);
    // Was sich nicht in eine Karte übersetzen lässt, fällt weg — das
    // verwirft den Fund, nicht den Tag.
    if (karte == null || !gesehen.add(karte.id)) return;
    ernte.add(karte);
  }

  nimm(feed.article);
  for (final DailyItem event in feed.events.take(maxEvents.clamp(0, 10))) {
    nimm(event);
  }
  return ernte;
}
