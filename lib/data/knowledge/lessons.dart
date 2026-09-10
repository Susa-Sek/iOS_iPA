import 'package:flutter/foundation.dart';

import '../../models/vocabulary.dart';
import 'knowledge_data.dart';

/// Eine Lektion: der Weg, auf dem Wissen in dieser App gelernt wird.
///
/// **Warum keine Kartei.** Vokabeln sind willkürliche Paare — „Haus" und
/// „بَيْت" haben nichts miteinander zu tun, das muss man stur wiederholen.
/// Wissen ist nicht willkürlich: Es hängt zusammen, und wer den Zusammenhang
/// einmal verstanden hat, braucht keine Karteikarte, sondern einen Text. Eine
/// Karte „Wolga | Längster Fluss Europas" lehrt ein Stück Trivia, kein
/// Verständnis.
///
/// Eine Lektion besteht deshalb aus **Lesestoff** und **Prüfung**: erst wird
/// gelesen, dann wird geprüft, was gerade stand, und am Ende steht, was man
/// mitnimmt.
@immutable
class KnowledgeLesson {
  const KnowledgeLesson({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.intro,
    required this.takeaway,
    required this.entries,
  });

  /// Bleibt stabil — es ist der Schlüssel im gespeicherten Fortschritt.
  final String id;

  final String categoryId;

  final String title;

  /// Ein Satz: worum es geht und warum es sich lohnt.
  final String intro;

  /// Zwei bis drei Kernsätze für den Schluss.
  final List<String> takeaway;

  final List<VocabEntry> entries;

  /// Die Begriffskarten — sie werden gelesen, nicht abgefragt.
  List<VocabEntry> get reading => <VocabEntry>[
        for (final VocabEntry e in entries)
          if (e.question == null) e,
      ];

  /// Die Fragen — sie prüfen, was gerade gelesen wurde.
  List<VocabEntry> get checks => <VocabEntry>[
        for (final VocabEntry e in entries)
          if (e.question != null) e,
      ];

  int get length => entries.length;

  @override
  String toString() => '$id „$title"';
}

/// Alle Lektionen, in der Reihenfolge der Themen.
List<KnowledgeLesson> get kLessons => <KnowledgeLesson>[
      for (final VocabCategory c in kKnowledgeCategories) ...lessonsOf(c),
    ];

/// Die Lektionen eines Themas.
///
/// Geteilt wird die Liste des Themas in zwei Hälften, in ihrer Reihenfolge —
/// nicht abgeschrieben. So gibt es keine zweite Wahrheit: Kommt eine Karte
/// dazu, verschiebt sich die Grenze, und die Lektion hält trotzdem. Dass
/// dabei in jeder Hälfte genug Lesestoff **und** genug Fragen bleiben, prüft
/// `lessons_test.dart` für den ganzen Bestand.
List<KnowledgeLesson> lessonsOf(VocabCategory category) {
  final List<VocabEntry> alle = category.entries;
  if (alle.length < 4) return const <KnowledgeLesson>[];

  final int mitte = alle.length ~/ 2;
  final List<List<VocabEntry>> haelften = <List<VocabEntry>>[
    alle.sublist(0, mitte),
    alle.sublist(mitte),
  ];

  return <KnowledgeLesson>[
    for (int i = 0; i < haelften.length; i++)
      () {
        final String id = '${category.id}.${i + 1}';
        final _LessonText text = _texte[id] ?? _LessonText.fehlt(i + 1);
        return KnowledgeLesson(
          id: id,
          categoryId: category.id,
          title: text.title,
          intro: text.intro,
          takeaway: text.takeaway,
          entries: haelften[i],
        );
      }(),
  ];
}

KnowledgeLesson? lessonById(String id) {
  for (final KnowledgeLesson lesson in kLessons) {
    if (lesson.id == id) return lesson;
  }
  return null;
}

/// Titel, Einstieg und Fazit einer Lektion.
@immutable
class _LessonText {
  const _LessonText(this.title, this.intro, this.takeaway);

  /// Notnagel für eine Lektion ohne Text. Die App bleibt benutzbar, und
  /// `lessons_test.dart` schlägt an — dort ist so ein Titel verboten.
  const _LessonText.fehlt(int teil)
      : title = 'Teil $teil',
        intro = '',
        takeaway = const <String>[];

  final String title;
  final String intro;
  final List<String> takeaway;
}

/// Der geschriebene Teil: 42 Lektionen, zwei je Thema.
///
/// Kein neuer Wissensinhalt — nur die Klammer um die vorhandenen Karten:
/// wozu sie zusammengehören und was am Ende hängen bleiben soll.
const Map<String, _LessonText> _texte = <String, _LessonText>{
  // ---- Allgemeinbildung -------------------------------------------------
  'w_geografie.1': _LessonText(
    'Große Zahlen, große Namen',
    'Wie viele Kontinente, welcher Fluss der längste, welches Land das '
        'größte — die Eckdaten, an denen man sich auf jeder Karte festhält.',
    <String>[
      'Sieben Kontinente — und der Pazifik bedeckt allein ein Drittel der Erde.',
      'Die Wolga ist Europas längster Fluss und mündet ins Kaspische Meer.',
      'Bern ist Bundesstadt; formal hat die Schweiz gar keine Hauptstadt.',
    ],
  ),
  'w_geografie.2': _LessonText(
    'Meere, Wüsten und der Rest der Karte',
    'Wo Erdteile aneinanderstoßen, wo es am tiefsten ist und warum '
        'Nordeuropa milder liegt, als es dürfte.',
    <String>[
      'Der Ural trennt Europa und Asien — eine Übereinkunft, keine Naturgrenze.',
      'Im Baikalsee steckt rund ein Fünftel des flüssigen Süßwassers der Erde.',
      'Der Golfstrom macht Nordwesteuropa wärmer, als es auf dieser Breite zu erwarten wäre.',
    ],
  ),
  'w_geschichte.1': _LessonText(
    'Wendepunkte, die man datieren kann',
    'Ein paar Jahreszahlen tragen erstaunlich weit: Wer sie hat, kann fast '
        'jedes Ereignis dazwischen einsortieren.',
    <String>[
      '1914 bis 1918 und 1939 bis 1945 — die beiden Weltkriege.',
      'Am 9. November 1989 fiel die Mauer, am 3. Oktober 1990 folgte die Wiedervereinigung.',
      'Gutenbergs Druck um 1450 machte Wissen erstmals in großer Zahl vervielfältigbar.',
    ],
  ),
  'w_geschichte.2': _LessonText(
    'Vom Dampf zur Raumfahrt',
    'Zweihundert Jahre, in denen sich mehr verändert hat als in den '
        'zweitausend davor.',
    <String>[
      'Das Grundgesetz gilt seit dem 23. Mai 1949 — als Provisorium gedacht.',
      'Marie Curie erhielt als erster Mensch zwei Nobelpreise.',
      '1969 landeten die ersten Menschen auf dem Mond.',
    ],
  ),
  'w_natur.1': _LessonText(
    'Was die Welt zusammenhält',
    'Wasser, Luft, Schwerkraft, Atome — die Bausteine, aus denen alles '
        'andere folgt.',
    <String>[
      'Wasser ist H₂O: zwei Wasserstoffatome an einem Sauerstoffatom.',
      'Luft besteht zu rund 21 Prozent aus Sauerstoff und zu 78 aus Stickstoff.',
      'Volt misst Spannung, Ampere Stromstärke, Watt Leistung.',
    ],
  ),
  'w_natur.2': _LessonText(
    'Energie, Stoffe und das Leben',
    'Warum Holz schwimmt, wie schnell Licht ist und was in jeder Zelle '
        'steckt.',
    <String>[
      'Energie geht nicht verloren, sie wandelt sich um — ein Perpetuum mobile ist unmöglich.',
      'Licht legt rund 300.000 Kilometer je Sekunde zurück.',
      'Chlorophyll fängt das Sonnenlicht ein und macht Blätter grün.',
    ],
  ),
  'w_koerper.1': _LessonText(
    'Der Körper in Zahlen',
    '206 Knochen, 32 Zähne und ein Muskel, der nie Pause macht.',
    <String>[
      'Ein Erwachsener hat rund 206 Knochen und mit Weisheitszähnen 32 Zähne.',
      'Das Herz schlägt in Ruhe 60- bis 80-mal je Minute.',
      'Antibiotika wirken gegen Bakterien, nicht gegen Viren.',
    ],
  ),
  'w_koerper.2': _LessonText(
    'Was der Körper von selbst regelt',
    'Atmen, verdauen, sich wehren — das meiste läuft, ohne dass man daran '
        'denkt.',
    <String>[
      'Der Hirnstamm steuert Atmung und Herzschlag, auch im Schlaf.',
      'Nährstoffe werden vor allem im Dünndarm aufgenommen.',
      'Rund 60 Prozent des Körpergewichts sind Wasser.',
    ],
  ),
  'w_kunst.1': _LessonText(
    'Namen, die jeder einmal gehört haben sollte',
    'Goethe, Leonardo, Beethoven — und die Gattungen, in die sich fast '
        'jeder Text einordnen lässt.',
    <String>[
      'Goethes „Faust" erschien im ersten Teil 1808.',
      'Die „Mona Lisa" malte Leonardo da Vinci; sie hängt im Louvre.',
      'Beethovens Neunte trägt die Melodie der Europahymne.',
    ],
  ),
  'w_kunst.2': _LessonText(
    'Wie Kunst gemacht ist',
    'Epochen, Formen und ein paar Handgriffe, an denen man erkennt, womit '
        'man es zu tun hat.',
    <String>[
      'Der Barock reicht von etwa 1600 bis 1750.',
      'Picasso begründete den Kubismus mit: mehrere Blickwinkel zugleich.',
      'Ein Sonett hat 14 Verse.',
    ],
  ),
  'w_mathe.1': _LessonText(
    'Rechnen, das man im Kopf braucht',
    'Einmaleins, Prozente, Brüche — und der Unterschied zwischen '
        'Durchschnitt und Mitte.',
    <String>[
      '7 × 8 sind 56.',
      'Die Winkelsumme im Dreieck beträgt 180 Grad.',
      'Der Median ist der mittlere Wert und unempfindlich gegen Ausreißer.',
    ],
  ),
  'w_mathe.2': _LessonText(
    'Große Zahlen, kleine Wahrscheinlichkeiten',
    'Was „exponentiell" wirklich heißt und warum eine Milliarde neun Nullen '
        'hat.',
    <String>[
      'Eine Milliarde hat neun Nullen, eine Billion zwölf.',
      '2 hoch 10 ergibt 1024 — daher das Kibibyte.',
      'Exponentielles Wachstum wirkt lange harmlos und wird dann sehr schnell groß.',
    ],
  ),
  'w_astronomie.1': _LessonText(
    'Unser Sonnensystem',
    'Acht Planeten, ein durchschnittlicher Stern und Entfernungen, für die '
        'Kilometer nicht mehr taugen.',
    <String>[
      'Acht Planeten — Pluto gilt seit 2006 als Zwergplanet.',
      'Die Sonne ist ein Stern, nur sehr viel näher als alle anderen.',
      'Ein Lichtjahr ist eine Strecke, keine Zeit: rund 9,5 Billionen Kilometer.',
    ],
  ),
  'w_astronomie.2': _LessonText(
    'Warum der Himmel tut, was er tut',
    'Jahreszeiten, Finsternisse und ein Universum, das einen Anfang hat.',
    <String>[
      'Jahreszeiten entstehen durch die Neigung der Erdachse um 23,5 Grad.',
      'Licht braucht von der Sonne zur Erde etwa acht Minuten.',
      'Der Urknall liegt rund 13,8 Milliarden Jahre zurück.',
    ],
  ),
  'w_biologie.1': _LessonText(
    'Wer zu wem gehört',
    'Was ein Säugetier ausmacht, warum Spinnen keine Insekten sind und '
        'wieso ohne Insekten die Ernte ausfiele.',
    <String>[
      'Der Blauwal ist mit bis zu 30 Metern das größte Tier, das je gelebt hat.',
      'Spinnen haben acht Beine, Insekten sechs.',
      'Ohne Bestäubung durch Insekten fiele ein großer Teil der Ernte aus.',
    ],
  ),
  'w_biologie.2': _LessonText(
    'Überleben, jedes auf seine Art',
    'Zusammenleben, Winterschlaf und ein Säugetier, das Eier legt.',
    <String>[
      'Eine Flechte ist Pilz und Alge zugleich — eine Symbiose.',
      'Was man im Wald sammelt, ist nur der Fruchtkörper; der Pilz steckt im Boden.',
      'Wirbellose stellen weit über 90 Prozent aller Tierarten.',
    ],
  ),

  // ---- Technik & Digitales ----------------------------------------------
  'w_computer.1': _LessonText(
    'Woraus ein Rechner besteht',
    'Bits, ein Prozessor, Speicher und ein Programm, das alles verwaltet — '
        'im Kern ist es nicht mehr.',
    <String>[
      'Acht Bit ergeben ein Byte; damit lassen sich 256 Werte darstellen.',
      'Arbeitsspeicher ist beim Ausschalten leer, eine Festplatte nicht.',
      'Ein Algorithmus ist eine eindeutige Folge von Anweisungen.',
    ],
  ),
  'w_computer.2': _LessonText(
    'Wörter, die im Alltag fallen',
    'Open Source, Cloud, Backup, Bug — Begriffe, die jeder benutzt und '
        'selten jemand erklärt.',
    <String>[
      'Open Source heißt einsehbarer Quelltext — nicht zwingend kostenlos.',
      'Cloud heißt: Die Daten liegen auf fremden Rechnern.',
      'Eine Kopie auf derselben Festplatte ist kein Backup.',
    ],
  ),
  'w_internet.1': _LessonText(
    'Wie ein Aufruf ins Netz geht',
    'Von der Adresse über den Router zum Server — und was das s in https '
        'bedeutet.',
    <String>[
      'Eine IP-Adresse ist die Anschrift eines Geräts im Netz.',
      'DNS übersetzt Namen wie example.org in IP-Adressen.',
      'Das s in https heißt: Die Verbindung ist verschlüsselt.',
    ],
  ),
  'w_internet.2': _LessonText(
    'Schnell, langsam und wer mitliest',
    'Bandbreite ist nicht Geschwindigkeit, und ein VPN schützt weniger, als '
        'viele denken.',
    <String>[
      'Bandbreite ist die Datenmenge je Zeit, Latenz die Verzögerung.',
      'Ein VPN schützt die Verbindung — nicht vor allem anderen.',
      'Cookies sind nützlich zum Angemeldetbleiben und geeignet zum Verfolgen.',
    ],
  ),
  'w_sicherheit.1': _LessonText(
    'Die Grundlagen der eigenen Sicherheit',
    'Ein gutes Passwort, ein zweiter Faktor und der Unterschied zwischen '
        'verschlüsselt und wirklich verschlüsselt.',
    <String>[
      'Lang schlägt kompliziert — und für jeden Dienst ein eigenes Passwort.',
      'Mit zwei Faktoren nützt ein gestohlenes Passwort allein nichts.',
      'Ende-zu-Ende heißt: Auch der Anbieter kann nicht mitlesen.',
    ],
  ),
  'w_sicherheit.2': _LessonText(
    'Was schiefgehen kann — und was hilft',
    'Erpressung, Datenspuren und die einfachste Vorsorge, die es gibt.',
    <String>[
      'Gegen Ransomware hilft ein Backup an einem getrennten Ort.',
      'Sicherheitsupdates schließen Lücken, die binnen Tagen ausgenutzt werden.',
      'Absender lassen sich fälschen — wohin ein Link führt, nicht.',
    ],
  ),
  'w_ki.1': _LessonText(
    'Was hinter dem Wort steckt',
    'Regeln aus Beispielen statt programmierter Regeln — und warum die '
        'Daten entscheiden.',
    <String>[
      'Maschinelles Lernen leitet Regeln aus Beispielen ab.',
      'Ist die Auswahl der Trainingsdaten schief, ist das Ergebnis es auch.',
      'Eine Halluzination ist eine erfundene, plausibel klingende Aussage.',
    ],
  ),
  'w_ki.2': _LessonText(
    'Im Umgang damit',
    'Was Sprachmodelle können, was sie kosten und wo die Verantwortung '
        'bleibt.',
    <String>[
      'Ein Sprachmodell sagt das nächste Wort voraus — daraus entsteht der Eindruck von Verständnis.',
      'Das Training kostet weit mehr Strom als der spätere Betrieb.',
      'Verantwortlich bleibt, wer die Ausgabe verwendet.',
    ],
  ),
  'w_alltagstechnik.1': _LessonText(
    'Strom im Haus',
    'Watt, Kilowattstunde, Sicherung, FI — was auf jeder Rechnung und in '
        'jedem Sicherungskasten vorkommt.',
    <String>[
      'Watt ist Leistung, die Kilowattstunde eine Energiemenge.',
      'Die Sicherung schützt die Leitung, der FI-Schalter den Menschen.',
      'Eine LED braucht rund ein Zehntel der Energie einer Glühlampe.',
    ],
  ),
  'w_alltagstechnik.2': _LessonText(
    'Geräte, die klug benutzt sein wollen',
    'Kühlschrank, Wärmepumpe, Standby — wo sich sparen lohnt und wo nicht.',
    <String>[
      '7 °C im Kühlschrank, −18 °C im Gefrierfach.',
      'Eine Wärmepumpe macht aus einer Einheit Strom mehrere Einheiten Wärme.',
      'Bei IP68 steht die erste Ziffer für Staub, die zweite für Wasser.',
    ],
  ),
  'w_energie.1': _LessonText(
    'Woher der Strom kommt',
    'Sonne, Wind, Wasser — und warum das Netz jederzeit im Gleichgewicht '
        'sein muss.',
    <String>[
      'Photovoltaik macht aus Licht Strom, Solarthermie Wärme.',
      'Ein Windrad treibt einen Generator an, der Drehung in Strom wandelt.',
      'Grundlast ist der Bedarf, der praktisch immer besteht.',
    ],
  ),
  'w_energie.2': _LessonText(
    'Was dabei verloren geht',
    'Wirkungsgrad, Abwärme — und die günstigste Energie überhaupt.',
    <String>[
      'Ein Kohlekraftwerk nutzt nur rund 40 Prozent der eingesetzten Energie.',
      'Kernspaltung trennt schwere Kerne, Kernfusion verschmilzt leichte.',
      'Die günstigste Energie ist die, die gar nicht gebraucht wird.',
    ],
  ),

  // ---- Politik, Wirtschaft, Gesellschaft --------------------------------
  'w_staat.1': _LessonText(
    'Wie der Staat gebaut ist',
    'Verfassung, drei Gewalten und die Frage, wer eigentlich wen wählt.',
    <String>[
      'Die Würde des Menschen ist unantastbar — Artikel 1, unveränderbar.',
      'Gesetzgebung, Regierung und Rechtsprechung sollen einander begrenzen.',
      'Den Bundeskanzler wählt der Bundestag, nicht das Volk.',
    ],
  ),
  'w_staat.2': _LessonText(
    'Wer worüber entscheidet',
    'Bund und Länder, Karlsruhe — und die Grenzen jeder Mehrheit.',
    <String>[
      'Schule und Polizei sind Sache der Länder.',
      'Das Bundesverfassungsgericht kann Gesetze für nichtig erklären.',
      'Menschenwürde und Bundesstaat sind jeder Änderung entzogen.',
    ],
  ),
  'w_wahlen.1': _LessonText(
    'Was die Stimme bewirkt',
    'Erst- und Zweitstimme tun Verschiedenes — und nur eine entscheidet über '
        'die Stärke der Parteien.',
    <String>[
      'Die Zweitstimme bestimmt die Sitzverteilung im Bundestag.',
      'Die Fünf-Prozent-Hürde soll Zersplitterung verhindern.',
      'Geheim heißt: Niemand darf erfahren, wie man gewählt hat.',
    ],
  ),
  'w_wahlen.2': _LessonText(
    'Wie aus Stimmen Sitze werden',
    'Wahlkreise, Verhältniswahl — und was ein Parteiprogramm wert ist.',
    <String>[
      'Deutschland ist in 299 Wahlkreise eingeteilt.',
      'Bei der Verhältniswahl zählen Anteile, beim Mehrheitswahlrecht nur der Sieger.',
      'Ein Parteiprogramm sagt, wofür eine Partei stehen will — nicht, was sie tun wird.',
    ],
  ),
  'w_europa.1': _LessonText(
    'Europa und die Vereinten Nationen',
    '27 Staaten, eine Währung, ein Raum ohne Grenzkontrollen — und ein Rat '
        'mit fünf Vetos.',
    <String>[
      'Die EU hat 27 Mitgliedstaaten; Schengen ist damit nicht deckungsgleich.',
      'Der Euro ist seit 2002 Bargeld, aber nicht in allen Mitgliedstaaten.',
      'Fünf Staaten haben im UN-Sicherheitsrat ein Vetorecht.',
    ],
  ),
  'w_europa.2': _LessonText(
    'Regeln zwischen Staaten',
    'Bündnis, Kriegsrecht, Klima — und wer in Brüssel eigentlich Gesetze '
        'vorschlägt.',
    <String>[
      'Der NATO-Beistandsfall steht in Artikel 5 des Vertrags.',
      'Die Genfer Konventionen schützen Verwundete, Gefangene und Zivilisten.',
      'In der EU schlägt die Kommission vor, Parlament und Rat beschließen.',
    ],
  ),
  'w_recht.1': _LessonText(
    'Rechte, die im Alltag greifen',
    'Verträge, Widerruf, Volljährigkeit — was gilt, ohne dass man je vor '
        'Gericht steht.',
    <String>[
      'Ein Vertrag kann auch mündlich zustande kommen.',
      'Bei Käufen im Netz gilt meist ein Widerrufsrecht von vierzehn Tagen.',
      'Voll geschäftsfähig ist man mit 18.',
    ],
  ),
  'w_recht.2': _LessonText(
    'Vor Gericht',
    'Wer anklagt, wer aussagt — und was im Zweifel gilt.',
    <String>[
      'Die Staatsanwaltschaft klagt an, die Polizei ermittelt, das Gericht entscheidet.',
      'Im Zweifel für den Angeklagten: Bewiesen werden muss die Schuld.',
      'Die Meinungsfreiheit endet, wo andere Rechte verletzt werden.',
    ],
  ),
  'w_wirtschaft.1': _LessonText(
    'Preise, Zinsen, Erträge',
    'Drei Wörter aus jeder Wirtschaftsnachricht — und wie sie zusammenhängen.',
    <String>[
      'Inflation heißt: Für dasselbe Geld bekommt man weniger.',
      'Den Leitzins setzt in der Eurozone die Europäische Zentralbank.',
      'Höhere Rendite geht regelmäßig mit höherem Risiko einher.',
    ],
  ),
  'w_wirtschaft.2': _LessonText(
    'Geld über die Zeit',
    'Zinseszins, Konjunktur — und warum sinkende Preise kein Grund zur '
        'Freude sind.',
    <String>[
      'Über lange Zeiträume wirkt der Zinseszins stärker als die Einzahlung.',
      'Nicht alles auf eine Karte: Diversifikation verteilt das Risiko.',
      'Deflation klingt gut, lähmt aber Investitionen und Konsum.',
    ],
  ),
  'w_arbeit.1': _LessonText(
    'Was im Arbeitsvertrag mitläuft',
    'Fünf Versicherungen, ein Mindestlohn und Rechte, die nicht verhandelt '
        'werden müssen.',
    <String>[
      'Die Sozialversicherung hat fünf Zweige: Kranken, Pflege, Rente, Arbeitslosigkeit, Unfall.',
      'Ein Tarifvertrag gilt für eine ganze Branche, nicht für einen Einzelnen.',
      'Bei einer Fünftagewoche stehen mindestens 20 Urlaubstage zu.',
    ],
  ),
  'w_arbeit.2': _LessonText(
    'Wenn etwas dazwischenkommt',
    'Rente, Elternzeit, Kurzarbeit — und wer das alles bezahlt.',
    <String>[
      'Die Rente läuft im Umlageverfahren: Die Beiträge von heute zahlen die Renten von heute.',
      'Kurzarbeit soll Entlassungen in vorübergehenden Krisen vermeiden.',
      'Das Sozialstaatsprinzip steht in Artikel 20 und ist unabschaffbar.',
    ],
  ),
  'w_medien.1': _LessonText(
    'Woran man eine Quelle erkennt',
    'Impressum, Quellenangabe, Absicht — die drei Fragen vor dem Glauben.',
    <String>[
      'Fehlt das Impressum, ist niemand greifbar — ein Warnzeichen.',
      'Wer keine Quelle nennt, verlangt Glauben statt Prüfung.',
      'Der Unterschied zwischen Irrtum und Desinformation ist die Absicht.',
    ],
  ),
  'w_medien.2': _LessonText(
    'Bevor man teilt',
    'Werten oder schildern, prüfen oder weiterreichen — und warum Klicks '
        'nichts beweisen.',
    <String>[
      'Der Kommentar wertet, der Bericht schildert; seriöse Medien machen das kenntlich.',
      'Vor dem Teilen prüfen: wer verbreitet es, und wann ist es entstanden.',
      'Aufmerksamkeit richtet sich nicht nach Richtigkeit.',
    ],
  ),
};
