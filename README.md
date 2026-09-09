# Arabisch lernen 🇩🇪 ↔ 🇸🇦

Ein interaktiver Arabisch-Deutsch-Vokabeltrainer, gebaut mit Flutter — für
Android und iOS aus demselben Code.

Die App ist komplett auf Deutsch, zeigt jedes Wort in arabischer Schrift und
mit Lautschrift und besteht nicht aus Listen zum Durchlesen, sondern aus
Übungen zum Mitmachen.

**Jedes arabische Wort ist vollständig vokalisiert** — mit Fatḥa, Kasra,
Ḍamma, Sukūn, Shadda und Tanwīn (شُكْرًا statt شكرا). Ohne diese Zeichen
schreibt Arabisch nur die Konsonanten, und Anfänger können nicht wissen, wie
ein Wort klingt.

## Übungen

| Übung | Was man macht |
| --- | --- |
| **Karteikarten** | Wort aufdecken und selbst einschätzen — Vorderseite wahlweise Deutsch oder Arabisch. |
| **Quiz** | Multiple Choice mit vier Antworten, in beide Richtungen (Arabisch → Deutsch und umgekehrt). |
| **Zuordnen** | Deutsches Wort antippen, dann das passende arabische — gelöste Paare verschwinden. |
| **Wort bauen** | Das arabische Wort aus durcheinandergewürfelten Buchstaben zusammensetzen. |
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

## Wortschatz

Rund 300 vollständig vokalisierte Wörter und Wendungen in 16 Themen:
Allgemein, Sich vorstellen,
Begrüßung & Abschied, Reise, Wegbeschreibungen, Zeit & Datum, Orte,
Einkaufen, Im Restaurant, Im Hotel, Zahlen, Personalpronomen, Wichtige
Wörter, Mensch & Körper, Wichtige Verben, Wichtige Adjektive.

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
├── data/                  Wortschatz und Alphabet
├── state/                 Lernstufen & Termine, Speicherung, Sprachausgabe
├── screens/               Start, Thema, Karteikarten, Quiz, Zuordnen,
│                          Wort bauen, Alphabet & Zeichen, Suche,
│                          Quran-Übersicht, Sure, Wurzeln
└── widgets/               Arabische Textausgabe (RTL), Wortzeile, Lernboxen
```

## Entwickeln

```bash
flutter pub get
flutter test        # Daten, Lernlogik, Speicherung, Sprachausgabe, Layout
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
