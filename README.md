# Täglich Klüger

Eine Lern-App auf Deutsch, gebaut mit Flutter — für Android und iOS aus
demselben Code. Zwei Fächer unter einem Dach:

* **Arabisch**, vollständig vokalisiert, mit Alphabet, Verben und
  Quran-Sprache — der ursprüngliche Kern der App.
* **Allgemeinwissen** in drei Fächern: Allgemeinbildung, Technik & Digitales,
  Politik/Wirtschaft/Gesellschaft.

Dazu jeden Tag etwas Neues aus dem Netz im Bereich „Heute".

Es ist bewusst **eine** App geblieben: Die Lernmechanik — Leitner-Termine,
Punkte, Serie, Erinnerung — ist themenneutral. Zwei Apps würden sie
duplizieren und die Tagesserie zerteilen, also genau das zerstören, was zum
täglichen Lernen führt.

> Der Paket- und Ordnername lautet weiterhin `de.susasek.arabischlernen`. Das
> ist Absicht: Er ist kein Anzeigename, sondern die Identität der
> Installation. Würde er sich ändern, gälte die App auf jedem Gerät als neu —
> ohne Lernstand. `test/naming_test.dart` friert ihn und alle sechs
> Speicher-Schlüssel ein.

Die App besteht nicht aus Listen zum Durchlesen, sondern aus Übungen zum
Mitmachen.

**Alle 801 arabischen Wörter sind vollständig vokalisiert** — mit Fatḥa,
Kasra, Ḍamma, Sukūn, Shadda und Tanwīn (شُكْرًا statt شكرا). Ohne diese
Zeichen schreibt Arabisch nur die Konsonanten, und Anfänger können nicht
wissen, wie ein Wort klingt. Ein Test setzt das durch: kommt ein Wort ohne
Zeichen dazu, schlägt er an.

## Ein Fach zur Zeit

Oben auf „Lernen" stehen zwei Knöpfe: **Arabisch** und **Wissen**. Es ist
immer genau eines aktiv, und alles folgt der Wahl — Tagesportion, Lernweg,
jede Übung, die Zahl unten am Symbol. Eine Runde aus Vokabeln und
Wissensfragen durcheinander lernt sich schlechter als zehn Minuten in einer
Sache.

Die Leiste bleibt beim Scrollen stehen; der Fachwechsel ist der häufigste
Griff auf dieser Seite.

**Damit nichts verschwindet**, trägt der *nicht* gewählte Knopf die Zahl
seiner offenen Wiederholungen. Gezählt werden nur angefangene Wörter, deren
Termin gekommen ist — ein nie angesehenes Wort wäre eine Zahl, die sich nie
ändert. Die Abenderinnerung zählt beide Fächer zusammen, und die **Abzeichen
hängen nicht am Fach**: Wer umschaltet, hat nichts verlernt.

## Aufbau der App

Unten vier Bereiche, statt alles auf einer Seite:

| Bereich | Inhalt |
| --- | --- |
| **Lernen** | Was heute fällig ist, Tagesziel, Serie, Level — darunter der Lernweg mit allen Themen. Die Zahl am Symbol zeigt die fälligen Wörter. |
| **Üben** | Alle Übungen und alles zum Nachschlagen, jeweils mit einem Satz dazu, was einen erwartet. |
| **Heute** | Artikel des Tages, „Was geschah heute" und Nachrichten — jeden Tag neu. |
| **Erfolge** | Level, Punkte, Serie und die zwölf Abzeichen. |

## Bereich „Heute"

Einmal am Tag holt die App drei Dinge aus dem Netz: den **Artikel des Tages**
und **„Was geschah heute"** von der deutschen Wikipedia (beides in einem
einzigen Aufruf) sowie die **Nachrichten** der Tagesschau — von dort nur
Überschrift, Dachzeile und erster Satz, kein Volltext. Quelle und Lizenz
(Wikipedia, CC BY-SA 4.0) stehen unter den Karten.

Was gefällt, wandert mit **„Als Karte merken"** unter *Meine Karten* und läuft
danach durch dieselbe Wiederholung wie der übrige Wortschatz. Ein Ereignis
wird dabei zur Frage „In welchem Jahr …?" mit drei plausiblen Jahreszahlen
zur Auswahl, der Artikel des Tages zur Begriffskarte.

**Nachrichten lassen sich nicht merken.** Sie sind morgen überholt und hätten
in einer Wiederholung nach drei Wochen nichts mehr zu suchen.

Der Bereich lädt erst, wenn man ihn öffnet, und merkt sich den Stand für den
Tag. Ohne Netz steht der letzte Stand mit seinem Datum da statt einer
Fehlermeldung ins Leere — der Rest der App braucht kein Netz.

## Wissen neben Sprache

Neben rund 800 arabischen Wörtern stecken jetzt **301 Wissenskarten** in der
App, in drei Fächern und 21 Themen:

| Fach | Themen |
| --- | --- |
| **Allgemeinbildung** | Geografie, Geschichte, Naturwissenschaft, Körper & Medizin, Kunst & Literatur, Mathematik, Astronomie, Tiere & Pflanzen |
| **Technik & Digitales** | Computer-Grundlagen, Internet & Netze, Datenschutz & Sicherheit, Künstliche Intelligenz, Alltagstechnik, Energie |
| **Politik, Wirtschaft, Gesellschaft** | Staat & Verfassung, Wahlen & Parteien, Europa & Welt, Recht & Rechte, Wirtschaft & Geld, Arbeit & Soziales, Medien |

Jede Karte ist entweder ein **Begriff** mit seiner Bedeutung oder eine **Frage
mit vier Antworten** und einer Erklärung, die nach dem Antworten erscheint.

**Regel für den festen Bestand: keine Frage, deren Antwort sich ändern kann.**
Wer gerade Bundeskanzler ist, gehört in den Bereich „Heute" — nicht in eine
Karte, die in drei Wochen wiederkommt.

## Tippen

Die härteste der Übungen: Die Antwort wird selbst geschrieben, statt aus
vieren gewählt. Bei vier Antworten erkennt man oft wieder, was man nicht
abrufen könnte.

Getippt wird immer die **deutsche** Seite — ein arabisches Wort lässt sich auf
einer deutschen Tastatur nicht eingeben. Verglichen wird nachsichtig: Groß-
und Kleinschreibung, Umlautpunkte, Satzzeichen und ein vorangestellter Artikel
entscheiden nichts, und ein Tippfehler in einem längeren Wort zählt als
gewusst („Fast — so wird es geschrieben"). **Nachsicht endet aber dort, wo
eine falsche Antwort durchginge:** „Totes Meer" ist von „Rotes Meer" nur einen
Buchstaben entfernt und trotzdem ein anderes Meer. Liegt die Eingabe genauso
nah an einem Ablenker wie an der Antwort, zählt sie nicht.

## Kurzrunde — zwei Minuten zwischendurch

Ein Knopf ganz oben auf „Lernen" startet eine gemischte Runde: drei Blöcke
verschiedener Übungsarten, etwa acht Aufgaben, dann eine Bilanz. Ein Griff,
und man ist beschäftigt — kein Bereich, keine Übung, keine Richtung wählen.

Die Zusammenstellung entsteht aus dem, was gerade fällig ist, und **nie
zweimal dieselbe Art hintereinander**. Welche Arten möglich sind, ergibt sich
aus dem Vorrat: Im Fach Wissen fällt „Wort bauen" von selbst weg, weil es dort
keine arabischen Buchstaben zu bauen gibt.

Der Fortschrittsbalken oben gilt für die **ganze** Runde, nicht für den
laufenden Block — man sieht, dass es gleich vorbei ist, und hört deshalb nicht
mittendrin auf.

## Tagesportion statt Marathon

Karteikarten und Quiz zeigen nicht den ganzen Bestand, sondern eine Portion:
fällige und schwache Karten zuerst, dann ist Schluss. Die Portion wächst mit
dem Tagesziel — wer sich mehr vornimmt, bekommt mehr. Ein Stapel mit über
tausend Karten ist keine Übung, sondern eine Drohung; wer ihn einmal sieht,
fängt gar nicht erst an. Ein ausgewähltes Thema wird weiterhin ganz
durchgearbeitet.

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

## Das Symbol

Ein fast geschlossener Ring — die Tagesrunde, die sich füllt — und ein Funke
darin. Erzeugt wird es aus einer einzigen Zeichnung:

```bash
python3 tool/make_icons.py             # alle Größen schreiben
python3 tool/make_icons.py --preview   # nur ansehen
```

Das Skript schreibt Android (Symbol, adaptives Vordergrundbild,
Benachrichtigung), iOS und Web. Es liegt bewusst im Repository: Der Erzeuger
des ersten Symbols lag nur in einem Arbeitsverzeichnis und ist weg — jenes
Symbol ließe sich heute nicht mehr nachbauen.

Das **Benachrichtigungssymbol** bleibt eine flache weiße Silhouette. Android
färbt es selbst ein und benutzt nur den Alphakanal; alles mit Farbverlauf
würde dort zu einem grauen Klecks.

## Projektstruktur

```
lib/
├── main.dart              App, Theme (hell & dunkel)
├── models/                VocabEntry, VocabCategory, ArabicLetter,
│                          ArabicDiacritic + Tashkīl-Hilfsfunktionen
├── theme/                 Abstände, Radien, Bewegung, Erscheinungsbild
├── state/                 Lernstufen & Termine, Speicherung, Punkte,
│                          Sprachausgabe, Erinnerungen, Tagesinhalte,
│                          gemerkte Karten
├── data/                  Wortschatz, Lernweg, Registry, Alphabet, Verben,
│                          Quran
├── screens/               Start, Heute, Thema, Karteikarten, Quiz, Zuordnen,
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

## Quellen der Tagesinhalte

| Quelle | Aufruf | Lizenz |
| --- | --- | --- |
| Wikipedia | `de.wikipedia.org/api/rest_v1/feed/featured/JJJJ/MM/TT` | CC BY-SA 4.0, im Bereich genannt |
| Tagesschau | `tagesschau.de/api2u/news` (ohne Schrägstrich am Ende) | nur Überschrift und erster Satz, mit Verweis |

Beide sind ohne Vertrag nutzbar, aber auch ohne Zusage. Die App muss deshalb
ohne sie vollständig funktionieren — der Feed ist Beiwerk, nicht Fundament.
Getestet wird er gegen abgelegte echte Antworten unter `test/data/`, nicht
gegen das Netz.

## Eigenen Signaturschlüssel benutzen

Ohne eigenen Schlüssel wird das Release-APK mit dem **Debug-Schlüssel**
signiert. Es lässt sich installieren, aber **nicht** in den Play Store laden —
und ein Update, das ein anderer Rechner baut, gilt als andere App.

Einen eigenen Schlüssel erzeugt nur der Besitzer, niemand sonst:

```bash
keytool -genkey -v -keystore ~/upload.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload
```

Dann `android/key.properties` anlegen — die Datei steht in `.gitignore` und
gehört nie ins Repository:

```properties
storeFile=/absoluter/pfad/upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Ist die Datei da, signiert `flutter build apk --release` damit; fehlt sie,
läuft der Bau unverändert mit dem Debug-Schlüssel weiter. Beide Wege sind
geprüft: einmal ohne Datei, einmal mit einem Wegwerfschlüssel, dessen Zertifikat
danach im APK stand.

Für GitHub Actions dieselben Werte als Secrets hinterlegen —
`ANDROID_KEYSTORE_BASE64` (`base64 -w0 upload.jks`),
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
Fehlen sie, baut der Workflow ebenfalls weiter.

**Den Schlüssel nie verlieren.** Ohne ihn lässt sich eine im Play Store
veröffentlichte App nicht mehr aktualisieren.

## Bewusst offen

Ehrlicher als eine halbe Umsetzung:

* **Beispielsätze auf Arabisch.** Rund 800 Sätze mit vollständigem Tashkīl zu
  schreiben ist eine eigene Etappe, keine Beigabe — und ohne Quelle nicht so
  prüfbar, wie es der Quran-Text ist. Wissenskarten tragen ihren Kontext
  dagegen schon in der Erklärung.
* **Schreibtrainer** (Buchstabenformen nachziehen). Bräuchte Zeichenfläche und
  Erkennung; „Wort bauen" übt dieselbe Fertigkeit ohne Gestenerkennung.
* **iOS.** Der Ordner steht weitgehend auf der Vorlage; Anzeigename und
  Version sind gesetzt. Ob ein `.ipa` durchläuft, **kann ich ohne Mac nicht
  nachprüfen** — der Workflow dafür liegt bereit, gebaut habe ich ihn nie.
* **Gerätefragen.** Ob die Erinnerung abends wirklich ankommt, wie die
  arabische Sprachausgabe klingt und ob die Tagesinhalte eintreffen, zeigt
  erst das Telefon.

## Herkunft

Das Repository geht auf ein Tutorial von
[AmirBayat0](https://github.com/AmirBayat0/iOS_iPA) zurück, das zeigt, wie
man eine Flutter-iOS-`.ipa` ohne Mac baut ([YouTube](https://youtu.be/mQMy12Sk0xM)).
Der iOS-Workflow stammt von dort.
