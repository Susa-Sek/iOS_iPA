# Arabisch lernen 🇩🇪 ↔ 🇸🇦

Ein interaktiver Arabisch-Deutsch-Vokabeltrainer, gebaut mit Flutter — für
Android und iOS aus demselben Code.

Die App ist komplett auf Deutsch, zeigt jedes Wort in arabischer Schrift und
mit Lautschrift und besteht nicht aus Listen zum Durchlesen, sondern aus
Übungen zum Mitmachen.

## Übungen

| Übung | Was man macht |
| --- | --- |
| **Karteikarten** | Wort aufdecken und selbst einschätzen — Vorderseite wahlweise Deutsch oder Arabisch. |
| **Quiz** | Multiple Choice mit vier Antworten, in beide Richtungen (Arabisch → Deutsch und umgekehrt). |
| **Zuordnen** | Deutsches Wort antippen, dann das passende arabische — gelöste Paare verschwinden. |
| **Wort bauen** | Das arabische Wort aus durcheinandergewürfelten Buchstaben zusammensetzen. |
| **Alphabet** | Alle 28 Buchstaben mit Aussprache-Hinweis und den vier Formen (allein, Anfang, Mitte, Ende). |

## Wie die App sich merkt, was noch wackelt

Jedes Wort sitzt in einer von vier Lernboxen (Leitner-Prinzip):

* richtige Antwort → eine Box weiter,
* falsche Antwort → zurück in Box 0,
* ab der letzten Box gilt ein Wort als **gelernt**.

Jede Übungsrunde zieht die Wörter aus den schwächsten Boxen zuerst — geübt
wird also genau das, was noch nicht sitzt. Fortschritt, Trefferquote und
Serie stehen auf der Startseite; pro Thema gibt es einen eigenen Balken.

> Der Lernstand liegt im Arbeitsspeicher und gilt für die laufende Sitzung.
> Absichtlich: Das Projekt kommt ohne zusätzliche Plugins aus, damit die
> Builds überall ohne Extra-Setup durchlaufen.

## Wortschatz

Rund 300 Wörter und Wendungen in 16 Themen: Allgemein, Sich vorstellen,
Begrüßung & Abschied, Reise, Wegbeschreibungen, Zeit & Datum, Orte,
Einkaufen, Im Restaurant, Im Hotel, Zahlen, Personalpronomen, Wichtige
Wörter, Mensch & Körper, Wichtige Verben, Wichtige Adjektive.

Als Inspiration für die Themenauswahl diente der
[Grundwortschatz Arabisch von Sprachheld](https://www.sprachheld.de/).

## Projektstruktur

```
lib/
├── main.dart              App, Theme (hell & dunkel)
├── models/                VocabEntry, VocabCategory, ArabicLetter
├── data/                  Wortschatz und Alphabet
├── state/                 Lernboxen, Statistik (ChangeNotifier)
├── screens/               Start, Thema, Karteikarten, Quiz, Zuordnen,
│                          Wort bauen, Alphabet, Suche
└── widgets/               Arabische Textausgabe (RTL), Wortzeile, Lernboxen
```

## Entwickeln

```bash
flutter pub get
flutter test        # Widget-, Übungs- und Datentests
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
