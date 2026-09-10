# Arabisch lernen 🇩🇪 ↔ 🇸🇦

Ein interaktiver Arabisch-Deutsch-Vokabeltrainer, gebaut mit Flutter — für
Android und iOS aus demselben Code.

Die App ist komplett auf Deutsch, zeigt jedes Wort in arabischer Schrift und
mit Lautschrift und besteht nicht aus Listen zum Durchlesen, sondern aus
Übungen zum Mitmachen.

**Alle 801 arabischen Wörter sind vollständig vokalisiert** — mit Fatḥa,
Kasra, Ḍamma, Sukūn, Shadda und Tanwīn (شُكْرًا statt شكرا). Ohne diese
Zeichen schreibt Arabisch nur die Konsonanten, und Anfänger können nicht
wissen, wie ein Wort klingt. Ein Test setzt das durch: kommt ein Wort ohne
Zeichen dazu, schlägt er an.

## Aufbau der App

Unten drei Bereiche, statt alles auf einer Seite:

| Bereich | Inhalt |
| --- | --- |
| **Lernen** | Was heute fällig ist, Tagesziel, Serie, Level — darunter der Lernweg mit allen Themen. Die Zahl am Symbol zeigt die fälligen Wörter. |
| **Üben** | Alle Übungen und alles zum Nachschlagen, jeweils mit einem Satz dazu, was einen erwartet. |
| **Erfolge** | Level, Punkte, Serie und die zwölf Abzeichen. |

## Übungen

| Übung | Was man macht |
| --- | --- |
| **Karteikarten** | Wort aufdecken und selbst einschätzen — Vorderseite wahlweise Deutsch oder Arabisch. |
| **Quiz** | Multiple Choice mit vier Antworten, in beide Richtungen (Arabisch → Deutsch und umgekehrt). |
| **Zuordnen** | Deutsches Wort antippen, dann das passende arabische — gelöste Paare verschwinden. |
| **Wort bauen** | Das arabische Wort aus durcheinandergewürfelten Buchstaben zusammensetzen. |
| **Erfolge** | Level, Punkte, Serie und zwölf Abzeichen — mit Fortschrittsbalken zum nächsten. |
| **Alphabet & Zeichen** | Alle 28 Buchstaben mit Aussprache-Hinweis und den vier Formen (allein, Anfang, Mitte, Ende) — dazu eine Übersicht der Tashkīl-Zeichen von Fatḥa bis Tanwīn, jeweils mit Beispiel. |
| **Hören → Deutsch** | Nur das gesprochene Wort ist gegeben. Die schwerste und nützlichste Richtung — nur verfügbar, wenn eine arabische Stimme installiert ist. |

## Quran-Sprache

Ein eigener Bereich für klassisches Arabisch:

* **Sechs kurze Suren Wort für Wort** — al-Fātiḥa, al-ʿAṣr, al-Kauṯar,
  al-Iḫlāṣ, al-Falaq, an-Nās. Jeder Vers mit arabischem Text, deutscher
  Verständnishilfe und jedem einzelnen Wort samt Bedeutung.
* **Die 100 häufigsten Wortformen**, ermittelt aus dem vollständigen Text:
  78.245 Wörter, davon entfallen 29.637 Vorkommen auf diese 100 Formen —
  rund 38 % des gesamten Textes. Gezählt werden Wortformen, nicht Wurzeln.
* **Zwölf Wurzeln** und die Wörter, die aus ihnen wachsen
  (ك·ت·ب → كَتَبَ، كِتَاب، كَاتِب، مَكْتُوب).

Der arabische Text stammt unverändert aus der Ausgabe `quran-simple` des
[Tanzil-Projekts](https://tanzil.net/) und wurde **nicht abgetippt**. Ein Test
vergleicht jeden Vers zeichenweise gegen die mitgelieferte Quellkopie
(`test/data/quran_reference.json`) — er hat beim Bauen bereits einen Fehler
gefunden, bei dem eine von Hand geschriebene Basmala optisch gleich, aber
byteweise anders war (Reihenfolge von Shadda und Fatḥa).

Die deutschen Zeilen sind eine schlichte Verständnishilfe zum Sprachenlernen
und ersetzen keine anerkannte Übersetzung.

## Aussprache

Jedes arabische Wort lässt sich anhören — auf der Karteikarte, im Quiz, in der
Wortliste, beim Alphabet und bei den Tashkīl-Zeichen. Die App nutzt die
Sprachausgabe des Geräts (`flutter_tts`) und spricht standardmäßig langsam.

Ist keine arabische Stimme installiert, bleibt die App still und erklärt beim
Antippen, wo man sie nachinstalliert — statt wortlos nichts zu tun. Die
Hör-Übung wird in diesem Fall übersprungen.

## Jeden Tag ein paar Wörter

Der Teil, der aus Vorsatz Gewohnheit macht:

* **Tägliche Erinnerung** als Benachrichtigung, Uhrzeit frei wählbar
  (Voreinstellung 19:00). An Tagen, an denen das Tagesziel schon geschafft
  ist, bleibt es still — die App plant die nächsten 14 Tage einzeln und
  lässt erledigte Tage aus, statt stur jeden Abend zu piepen.
* **Tagesziel** (Voreinstellung 10 Antworten) und **Serie**: 🔥 zählt die
  Tage in Folge, an denen das Ziel erreicht wurde.
* **Punkte und Level**: 10 Punkte je richtige Antwort, 2 für einen Versuch,
  50 extra für das erreichte Tagesziel, 25 für eine fehlerfreie Quizrunde.
  Level 2 ab 100 Punkten, Level 3 ab 400, Level 4 ab 900.
* **Zwölf Abzeichen** für Meilensteine — von „10 Wörter gelernt" über
  „7 Tage in Folge" bis „ein ganzes Thema gemeistert". Der Erfolge-Bildschirm
  zeigt auch, wie weit es bis zum nächsten ist.

Unter Android 13 und neuer fragt die App beim Einschalten nach der Erlaubnis
für Benachrichtigungen. Wird sie verweigert, sagt die App das offen, statt
eine Erinnerung zu versprechen, die nie ankommt.

## Wie die App sich merkt, was noch wackelt

Jedes Wort durchläuft sechs Stufen mit echten Wiederholungsterminen:

| Stufe | 0 | 1 | 2 | 3 | 4 | 5 |
| --- | --- | --- | --- | --- | --- | --- |
| nächste Wiederholung | heute | in 1 Tag | in 3 Tagen | in 7 Tagen | in 21 Tagen | in 60 Tagen |

Richtige Antwort → eine Stufe weiter, falsche → zurück auf Stufe 0. Ab Stufe 3
gilt ein Wort als **sitzt**. Die Startseite zeigt, was heute fällig ist, und
startet die Wiederholung mit einem Tippen.

Dazu ein Tagesziel (Voreinstellung: 10 Antworten) und eine Tagesserie: 🔥
zählt die Tage in Folge, an denen das Ziel erreicht wurde.

**Der Lernstand wird auf dem Gerät gespeichert** (`shared_preferences`) und
übersteht das Schließen der App. Ein beschädigter Speicher lässt die App
leer starten statt abzustürzen — auch das ist getestet.

## Wortschatz und Aufbau

**801 vollständig vokalisierte Wörter in 33 Themen**, geordnet in sechs
Bereichen — die Startseite zeigt den Lernweg von oben nach unten:

| Bereich | Themen | Wörter |
| --- | ---: | ---: |
| Erste Schritte — die Wörter, mit denen jedes Gespräch anfängt | 5 | 102 |
| Alltag — zu Hause, Einkaufen, Essen, Kleidung, Zeit | 7 | 176 |
| Unterwegs — Reise, Weg, Orte, Restaurant, Hotel | 5 | 97 |
| Mensch & Welt — Körper, Gesundheit, Gefühle, Arbeit, Natur, Technik | 9 | 190 |
| Bausteine der Sprache — Verben, Adjektive, Gegensätze, Mengen | 6 | 136 |
| Quran-Sprache — die häufigsten Wörter des Quran | 1 | 100 |

Dazu **Verbtabellen**: acht häufige Verben mit allen acht Personen in
Vergangenheit und Gegenwart (64 Formen). Arabisch zeigt die Person in der
Gegenwart über eine Vorsilbe an — أ für „ich", تـ für „du", يـ für „er",
نـ für „wir" —, und dieses Muster wiederholt sich bei fast jedem Verb.

Als Inspiration für die Themenauswahl diente der
[Grundwortschatz Arabisch von Sprachheld](https://www.sprachheld.de/).

Die Wörter stehen in Pausalform: innen voll vokalisiert, ohne Kasusendung am
Wortende — so, wie man sie einzeln ausspricht. Wo das Tanwīn zur Aussprache
gehört (شُكْرًا, غَدًا, مُبَاشَرَةً), steht es. Die Suche findet ein Wort mit
und ohne Zeichen: Wer كتاب tippt, findet كِتَاب.

## Projektstruktur

```
lib/
├── main.dart              App, Theme (hell & dunkel)
├── models/                VocabEntry, VocabCategory, ArabicLetter,
│                          ArabicDiacritic + Tashkīl-Hilfsfunktionen
├── data/                  Wortschatz, Lernweg, Alphabet, Verben, Quran
├── theme/                 Abstände, Radien, Bewegung, Erscheinungsbild
├── state/                 Lernstufen & Termine, Speicherung, Punkte,
│                          Sprachausgabe, Erinnerungen
├── data/                  Wortschatz, Lernweg, Registry, Alphabet, Verben
├── screens/               Start, Thema, Karteikarten, Quiz, Zuordnen,
│                          Wort bauen, Alphabet & Zeichen, Suche,
│                          Quran-Übersicht, Sure, Wurzeln, Verbtabellen,
│                          Navigationsgerüst, Übungsübersicht
└── widgets/               Arabische Textausgabe (RTL), Wortzeile, Lernboxen
```

## Entwickeln

```bash
flutter pub get
flutter test        # 154 Tests: Daten, Lernlogik, Speicherung, Sprachausgabe,
                    # Quran-Text gegen die Quelle, Verbtabellen,
                    # Erinnerungsplan, Punkte & Abzeichen, Registry,
                    # Layout auf drei Displaygrößen und bei 150 % Schrift
flutter analyze
flutter run
```

## Builds über GitHub Actions

| Workflow | Ergebnis |
| --- | --- |
| `.github/workflows/android.yml` | Analyse + Tests, danach `app-release.apk` und `app-release.aab` als Artefakte. Läuft bei Push/PR und manuell. |
| `.github/workflows/dart.yml` | Unsignierte iOS-`.ipa` (ohne Apple-Developer-Account), manuell über *Run workflow*. |

Die Android-Artefakte liegen nach dem Lauf unter *Actions → Run → Artifacts*.
Die APK ist mit dem Debug-Key signiert und damit zum Ausprobieren, nicht für
den Play Store gedacht.

## Herkunft

Das Repository geht auf ein Tutorial von
[AmirBayat0](https://github.com/AmirBayat0/iOS_iPA) zurück, das zeigt, wie
man eine Flutter-iOS-`.ipa` ohne Mac baut ([YouTube](https://youtu.be/mQMy12Sk0xM)).
Der iOS-Workflow stammt von dort.
