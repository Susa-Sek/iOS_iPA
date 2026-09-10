import 'package:flutter/material.dart';

import '../../models/vocabulary.dart';

typedef _K = VocabEntry;

/// Technik & Digitales — das, was man im Alltag benutzt, ohne es zu kennen.
const List<VocabCategory> kTechnik = <VocabCategory>[
  VocabCategory(
    id: 'w_computer',
    name: 'Computer-Grundlagen',
    icon: Icons.memory_outlined,
    color: Color(0xFF2E6E8A),
    softColor: Color(0x242E6E8A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Bit', 'Kleinste Informationseinheit: 0 oder 1',
          explanation: 'Acht Bit ergeben ein Byte.'),
      _K.question('Wie viele Bit hat ein Byte?', 'Acht',
          distractors: <String>['Vier', 'Zehn', 'Sechzehn'],
          explanation: 'Ein Byte kann 256 verschiedene Werte darstellen.'),
      _K.fact('Prozessor', 'Bauteil, das die Rechenbefehle ausführt',
          explanation: 'Auch CPU genannt, von central processing unit.'),
      _K.question('Was ist Arbeitsspeicher?',
          'Schneller Speicher für laufende Programme',
          distractors: <String>[
            'Dauerhafter Speicher für Dateien',
            'Der Bildschirmspeicher',
            'Ein Speicher im Netz'
          ],
          explanation: 'Er ist beim Ausschalten leer — anders als eine '
              'Festplatte.'),
      _K.fact('Betriebssystem', 'Programm, das Geräte und Programme verwaltet',
          explanation: 'Windows, Android, iOS, Linux.'),
      _K.question('Wofür steht die Abkürzung PDF?', 'Portable Document Format',
          distractors: <String>[
            'Public Data File',
            'Printed Document Form',
            'Personal Data Folder'
          ],
          explanation: 'Es hält das Aussehen eines Dokuments auf jedem Gerät '
              'gleich.'),
      _K.fact('Algorithmus', 'Eindeutige Folge von Anweisungen für eine Aufgabe',
          explanation: 'Ein Kochrezept ist einer, ein Sortierverfahren auch.'),
      _K.question('Was bedeutet Open Source?', 'Der Quelltext ist einsehbar',
          distractors: <String>[
            'Die Software ist kostenlos',
            'Die Software hat keine Lizenz',
            'Die Software hat keine Werbung'
          ],
          explanation: 'Offen heißt einsehbar und meist änderbar — nicht '
              'zwingend kostenlos.'),
      _K.fact('Datei', 'Benannte Einheit von Daten auf einem Speicher',
          explanation: 'Die Endung sagt, welches Programm sie lesen kann.'),
      _K.question('Was macht ein Compiler?',
          'Er übersetzt Quelltext in Maschinencode',
          distractors: <String>[
            'Er packt Dateien zusammen',
            'Er sucht Fehler im Netz',
            'Er zeigt Bilder an'
          ],
          explanation: 'Ein Interpreter führt den Quelltext dagegen Zeile für '
              'Zeile aus.'),
      _K.fact('Cloud', 'Rechner und Speicher, die anderen gehören',
          explanation: 'Bequem — aber die Daten liegen dann nicht mehr bei '
              'einem selbst.'),
      _K.question('Wie viele Byte hat ein Kilobyte nach SI?', '1000',
          distractors: <String>['1024', '100', '512'],
          explanation: '1024 Byte heißen korrekt ein Kibibyte; im Alltag wird '
              'beides vermischt.'),
      _K.fact('Backup', 'Zweite Kopie von Daten an einem anderen Ort',
          explanation: 'Eine Kopie auf derselben Festplatte ist keins.'),
      _K.question('Was ist ein Bug?', 'Ein Fehler in einem Programm',
          distractors: <String>[
            'Ein Schadprogramm',
            'Eine Netzwerkstörung',
            'Ein Bedienfehler'
          ],
          explanation: 'Der Ausdruck ist seit den 1940er-Jahren belegt.'),
    ],
  ),
  VocabCategory(
    id: 'w_internet',
    name: 'Internet & Netze',
    icon: Icons.router_outlined,
    color: Color(0xFF2E8A7A),
    softColor: Color(0x242E8A7A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('IP-Adresse', 'Nummer, unter der ein Gerät im Netz erreichbar ist',
          explanation: 'Wie eine Postanschrift für Datenpakete.'),
      _K.question('Wofür steht DNS?', 'Domain Name System',
          distractors: <String>[
            'Data Network Service',
            'Digital Name Server',
            'Direct Network Standard'
          ],
          explanation: 'Es übersetzt Namen wie example.org in IP-Adressen.'),
      _K.fact('Router', 'Gerät, das Datenpakete zwischen Netzen weiterleitet',
          explanation: 'Zu Hause verbindet er das Heimnetz mit dem Internet.'),
      _K.question('Was bedeutet das s in https?',
          'Die Verbindung ist verschlüsselt',
          distractors: <String>[
            'Die Seite ist besonders schnell',
            'Die Seite ist geprüft',
            'Die Seite ist statisch'
          ],
          explanation: 'Ohne s kann jeder auf dem Weg mitlesen.'),
      _K.fact('Browser', 'Programm zum Anzeigen von Webseiten',
          explanation: 'Er lädt HTML, CSS und Skripte und setzt daraus die '
              'Seite zusammen.'),
      _K.question('Was ist ein Server?', 'Ein Rechner, der Dienste bereitstellt',
          distractors: <String>[
            'Ein besonders schneller PC',
            'Ein Netzwerkkabel',
            'Ein Programm im Browser'
          ],
          explanation: 'Der anfragende Rechner heißt Client.'),
      _K.fact('WLAN', 'Drahtloses lokales Netz per Funk',
          explanation: 'Die Reichweite endet meist an den Wänden der '
              'Wohnung.'),
      _K.question('Was ist eine URL?', 'Die Adresse einer Ressource im Netz',
          distractors: <String>[
            'Ein Dateiformat',
            'Ein Verschlüsselungsverfahren',
            'Ein Netzwerkkabel'
          ],
          explanation: 'Sie nennt Protokoll, Rechner und Pfad.'),
      _K.fact('Bandbreite', 'Datenmenge, die je Zeit übertragen werden kann',
          explanation: 'Angegeben in Mbit/s — nicht dasselbe wie die '
              'Verzögerung.'),
      _K.question('Was misst die Latenz?', 'Die Verzögerung einer Übertragung',
          distractors: <String>[
            'Die Datenmenge',
            'Die Fehlerrate',
            'Die Signalstärke'
          ],
          explanation: 'Für Videotelefonie und Spiele wichtiger als die reine '
              'Geschwindigkeit.'),
      _K.fact('Suchmaschine', 'Dienst, der Webseiten durchsuchbar macht',
          explanation: 'Die Reihenfolge der Treffer bestimmt ein Programm, '
              'kein Mensch.'),
      _K.question('Was ist ein VPN?',
          'Ein verschlüsselter Tunnel durch ein fremdes Netz',
          distractors: <String>[
            'Ein besonders schnelles WLAN',
            'Ein Virenschutz',
            'Ein Werbeblocker'
          ],
          explanation: 'Es schützt die Verbindung — nicht vor allem '
              'anderen.'),
      _K.fact('Cookie', 'Kleine Datei, die eine Webseite im Browser ablegt',
          explanation: 'Nützlich zum Angemeldetbleiben, oft aber auch zum '
              'Verfolgen über Seiten hinweg.'),
      _K.question('Was leistet Glasfaser gegenüber Kupferkabel?',
          'Höhere Raten über weite Strecken',
          distractors: <String>[
            'Weniger Stromverbrauch im Haus',
            'Besseren WLAN-Empfang',
            'Billigere Endgeräte'
          ],
          explanation: 'Licht in Glas verliert unterwegs weit weniger Signal '
              'als Strom in Kupfer.'),
    ],
  ),
  VocabCategory(
    id: 'w_sicherheit',
    name: 'Datenschutz & Sicherheit',
    icon: Icons.lock_outline,
    color: Color(0xFF8A5A2E),
    softColor: Color(0x248A5A2E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Passwort', 'Geheimnis, mit dem man sich ausweist',
          explanation: 'Lang schlägt kompliziert — und für jeden Dienst ein '
              'eigenes.'),
      _K.question('Was ist Zwei-Faktor-Authentifizierung?',
          'Anmeldung mit zwei verschiedenen Nachweisen',
          distractors: <String>[
            'Zwei Passwörter hintereinander',
            'Zwei Konten für einen Dienst',
            'Ein doppelt langes Passwort'
          ],
          explanation: 'Etwa Passwort plus Code aus einer App — ein '
              'gestohlenes Passwort allein nützt dann nichts.'),
      _K.fact('Phishing', 'Täuschung, die Zugangsdaten abgreifen soll',
          explanation: 'Meist eine E-Mail, die aussieht wie von der Bank.'),
      _K.question('Was regelt die DSGVO?',
          'Den Umgang mit personenbezogenen Daten',
          distractors: <String>[
            'Die Netzgeschwindigkeit',
            'Den Jugendschutz im Netz',
            'Das Urheberrecht'
          ],
          explanation: 'Seit 2018 in der ganzen EU unmittelbar gültig.'),
      _K.fact('Verschlüsselung', 'Umwandlung von Daten in unlesbare Form',
          explanation: 'Nur wer den Schlüssel hat, kommt an den Inhalt.'),
      _K.question('Was heißt Ende-zu-Ende-Verschlüsselung?',
          'Nur Sender und Empfänger können mitlesen',
          distractors: <String>[
            'Der Anbieter verschlüsselt auf dem Server',
            'Die Leitung ist besonders schnell',
            'Die Nachricht löscht sich nach dem Lesen'
          ],
          explanation: 'Auch der Betreiber des Dienstes sieht dann nur '
              'unlesbare Daten.'),
      _K.fact('Schadprogramm', 'Software, die dem Nutzer schaden soll',
          explanation: 'Viren, Trojaner und Erpressungsprogramme gehören '
              'dazu.'),
      _K.question('Was macht Ransomware?',
          'Sie verschlüsselt Daten und fordert Lösegeld',
          distractors: <String>[
            'Sie zeigt Werbung',
            'Sie liest Passwörter mit',
            'Sie verlangsamt den Rechner'
          ],
          explanation: 'Ein aktuelles Backup an einem getrennten Ort ist der '
              'beste Schutz.'),
      _K.fact('Datensparsamkeit', 'Nur so viele Daten erheben wie nötig',
          explanation: 'Was nicht gespeichert ist, kann auch nicht gestohlen '
              'werden.'),
      _K.question('Warum sind Sicherheitsupdates wichtig?',
          'Sie schließen bekannte Lücken',
          distractors: <String>[
            'Sie machen das Gerät schneller',
            'Sie sparen Strom',
            'Sie schaffen Speicherplatz'
          ],
          explanation: 'Bekannt gewordene Lücken werden binnen Tagen '
              'ausgenutzt.'),
      _K.fact('Passwortmanager',
          'Programm, das Zugangsdaten verschlüsselt verwahrt',
          explanation: 'Man muss sich dann nur noch ein einziges Passwort '
              'merken.'),
      _K.question('Was verrät eine IP-Adresse üblicherweise?',
          'Ungefähren Ort und Anbieter',
          distractors: <String>[
            'Den Namen des Nutzers',
            'Das Passwort',
            'Den genauen Gerätetyp'
          ],
          explanation: 'Für die Zuordnung zu einer Person braucht es eine '
              'Auskunft des Anbieters.'),
      _K.fact('Anonymisierung', 'Entfernen des Personenbezugs aus Daten',
          explanation: 'Gelingt sie wirklich, gilt die DSGVO für diese Daten '
              'nicht mehr.'),
      _K.question('Woran erkennt man Phishing am ehesten?',
          'An Zeitdruck und am Ziel des Links',
          distractors: <String>[
            'An Rechtschreibfehlern allein',
            'An der Uhrzeit der Mail',
            'An der Dateigröße'
          ],
          explanation: 'Absenderadressen lassen sich leicht fälschen — wohin '
              'ein Link führt, nicht.'),
    ],
  ),
  VocabCategory(
    id: 'w_ki',
    name: 'Künstliche Intelligenz',
    icon: Icons.auto_awesome_outlined,
    color: Color(0xFF5A2E8A),
    softColor: Color(0x245A2E8A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Künstliche Intelligenz',
          'Programme, die Aufgaben lösen, die Denken erfordern',
          explanation: 'Der Begriff sagt nichts über Bewusstsein aus.'),
      _K.question('Was ist maschinelles Lernen?',
          'Regeln aus Beispielen ableiten',
          distractors: <String>[
            'Ein Rechner, der von selbst startet',
            'Programmieren ohne Tastatur',
            'Ein besonders schneller Prozessor'
          ],
          explanation: 'Statt die Regeln zu programmieren, findet das '
              'Programm Muster in Daten.'),
      _K.fact('Trainingsdaten', 'Beispiele, aus denen ein Modell lernt',
          explanation: 'Ist die Auswahl schief, ist das Ergebnis es auch.'),
      _K.question('Was bedeutet Bias in einem Modell?',
          'Eine systematische Verzerrung',
          distractors: <String>[
            'Ein Rechenfehler',
            'Eine langsame Antwort',
            'Ein Speicherproblem'
          ],
          explanation: 'Sie stammt meist aus den Daten, nicht aus dem '
              'Verfahren.'),
      _K.fact('Neuronales Netz',
          'Rechenmodell aus vielen einfachen, verbundenen Einheiten',
          explanation: 'Lose an Nervenzellen angelehnt — mehr als eine '
              'Anlehnung ist es nicht.'),
      _K.question('Was ist eine Halluzination bei Sprachmodellen?',
          'Eine erfundene, plausibel klingende Aussage',
          distractors: <String>[
            'Ein Absturz',
            'Ein Übersetzungsfehler',
            'Ein Bildfehler'
          ],
          explanation: 'Deshalb gehören Angaben aus solchen Modellen '
              'nachgeprüft.'),
      _K.fact('Sprachmodell', 'Modell, das das nächste Wort vorhersagt',
          explanation: 'Aus dieser einfachen Aufgabe entsteht der Eindruck '
              'von Sprachverständnis.'),
      _K.question('Wofür steht KI im Englischen?', 'AI',
          distractors: <String>['CI', 'ML', 'IT'],
          explanation: 'ML steht für machine learning, einen Teilbereich '
              'davon.'),
      _K.fact('Automatische Übersetzung',
          'Übertragung in eine andere Sprache durch ein Programm',
          explanation: 'Bei Fachtexten und Verträgen bleibt eine menschliche '
              'Prüfung nötig.'),
      _K.question('Warum brauchen große Modelle so viel Strom?',
          'Weil das Training enorm viele Rechenschritte kostet',
          distractors: <String>[
            'Weil sie ständig im Netz suchen',
            'Weil sie große Bildschirme brauchen',
            'Weil sie Daten kühlen müssen'
          ],
          explanation: 'Der spätere Betrieb ist deutlich günstiger als das '
              'einmalige Training.'),
      _K.fact('Datensatz', 'Geordnete Sammlung von Beispielen',
          explanation: 'Herkunft und Qualität entscheiden über das '
              'Ergebnis.'),
      _K.question('Darf man Ausgaben eines Sprachmodells ungeprüft übernehmen?',
          'Nein, sie können falsch sein',
          distractors: <String>[
            'Ja, sie sind geprüft',
            'Nur bei Zahlen',
            'Nur bei Texten'
          ],
          explanation: 'Verantwortlich bleibt, wer sie verwendet.'),
      _K.fact('Automatisierung', 'Übertragung von Arbeitsschritten an Maschinen',
          explanation: 'Sie verändert Berufe häufiger, als sie sie ersatzlos '
              'abschafft.'),
    ],
  ),
  VocabCategory(
    id: 'w_alltagstechnik',
    name: 'Alltagstechnik',
    icon: Icons.electrical_services_outlined,
    color: Color(0xFF8A7A2E),
    softColor: Color(0x248A7A2E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Was misst die Angabe Watt?', 'Leistung',
          distractors: <String>['Energiemenge', 'Spannung', 'Widerstand'],
          explanation: 'Energie misst man in Wattstunden — Leistung mal '
              'Zeit.'),
      _K.fact('Kilowattstunde', 'Einheit der Energiemenge auf der Stromrechnung',
          explanation: 'Ein Gerät mit 1000 Watt verbraucht in einer Stunde '
              'eine Kilowattstunde.'),
      _K.question('Warum wärmt eine Mikrowelle Speisen?',
          'Sie versetzt Wassermoleküle in Schwingung',
          distractors: <String>[
            'Sie strahlt Hitze ab',
            'Sie erzeugt Infrarotlicht',
            'Sie presst Luft zusammen'
          ],
          explanation: 'Deshalb wird trockenes Brot darin kaum warm.'),
      _K.fact('Sicherung', 'Schutz, der den Stromkreis bei Überlast trennt',
          explanation: 'Sie schützt in erster Linie die Leitung, nicht das '
              'Gerät.'),
      _K.question('Wozu dient ein FI-Schalter?',
          'Er trennt den Strom bei Fehlerstrom',
          distractors: <String>[
            'Er misst den Verbrauch',
            'Er glättet die Spannung',
            'Er schaltet das Licht'
          ],
          explanation: 'Er kann Leben retten, wenn Strom über einen Körper '
              'abfließt.'),
      _K.fact('LED', 'Leuchtdiode, die Strom sehr sparsam in Licht wandelt',
          explanation: 'Sie braucht rund ein Zehntel der Energie einer '
              'Glühlampe.'),
      _K.question('Was sagt die Energieeffizienzklasse A aus?',
          'Besonders geringen Verbrauch',
          distractors: <String>[
            'Besonders hohe Leistung',
            'Besonders lange Haltbarkeit',
            'Besonders leisen Betrieb'
          ],
          explanation: 'Die Skala reicht von A bis G.'),
      _K.fact('Akku', 'Wiederaufladbarer Speicher für elektrische Energie',
          explanation: 'Lithium-Ionen-Akkus altern auch dann, wenn man sie '
              'nicht benutzt.'),
      _K.question('Welche Temperatur wird für den Kühlschrank empfohlen?',
          'Etwa 7 °C',
          distractors: <String>['Etwa 0 °C', 'Etwa 12 °C', 'Etwa −18 °C'],
          explanation: '−18 °C gilt für das Gefrierfach.'),
      _K.fact('Wärmepumpe', 'Gerät, das Wärme aus der Umgebung ins Haus holt',
          explanation: 'Aus einer Einheit Strom werden mehrere Einheiten '
              'Wärme.'),
      _K.question('Warum gehören Elektrogeräte nicht in den Hausmüll?',
          'Sie enthalten Schadstoffe und Wertstoffe',
          distractors: <String>[
            'Sie sind zu schwer',
            'Sie sind zu groß',
            'Sie riechen'
          ],
          explanation: 'Rücknahmestellen sind gesetzlich vorgeschrieben.'),
      _K.fact('Standby', 'Bereitschaftsbetrieb mit geringem Dauerverbrauch',
          explanation: 'Über das Jahr summiert sich das in jedem Haushalt.'),
      _K.question('Was bedeutet die Schutzart IP68?',
          'Staubdicht und gegen Untertauchen geschützt',
          distractors: <String>[
            'Besonders bruchfest',
            'Besonders leicht',
            'Gegen Hitze geschützt'
          ],
          explanation: 'Die erste Ziffer steht für Staub, die zweite für '
              'Wasser.'),
    ],
  ),
  VocabCategory(
    id: 'w_energie',
    name: 'Energie',
    icon: Icons.bolt_outlined,
    color: Color(0xFF2E8A4A),
    softColor: Color(0x242E8A4A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Erneuerbare Energie', 'Energie aus Quellen, die sich erneuern',
          explanation: 'Sonne, Wind, Wasser, Biomasse und Erdwärme.'),
      _K.question('Welches Gas entsteht beim Verbrennen fossiler Energieträger?',
          'Kohlendioxid',
          distractors: <String>['Sauerstoff', 'Helium', 'Stickstoff'],
          explanation: 'CO₂ hält Wärme in der Atmosphäre zurück.'),
      _K.fact('Photovoltaik', 'Umwandlung von Sonnenlicht direkt in Strom',
          explanation: 'Solarthermie erzeugt dagegen Wärme.'),
      _K.question('Was macht ein Windrad mit der Drehbewegung?',
          'Es treibt einen Generator an',
          distractors: <String>[
            'Es erhitzt Wasser',
            'Es presst Luft zusammen',
            'Es speichert den Wind'
          ],
          explanation: 'Der Generator wandelt Drehung in Strom.'),
      _K.fact('Grundlast', 'Strombedarf, der praktisch immer besteht',
          explanation: 'Schwankende Quellen brauchen deshalb Speicher oder '
              'Ausgleich.'),
      _K.question('Welche Energieform steckt in einem gespannten Bogen?',
          'Potentielle Energie',
          distractors: <String>[
            'Kinetische Energie',
            'Wärmeenergie',
            'Elektrische Energie'
          ],
          explanation: 'Beim Loslassen wird sie zu Bewegungsenergie.'),
      _K.fact('Wirkungsgrad', 'Anteil der eingesetzten Energie, der nutzt',
          explanation: 'Der Rest geht meist als Wärme verloren.'),
      _K.question('Warum sind Speicher für die Energiewende wichtig?',
          'Weil Sonne und Wind nicht auf Abruf liefern',
          distractors: <String>[
            'Weil Strom sonst zu teuer ist',
            'Weil Leitungen zu dünn sind',
            'Weil Kraftwerke zu klein sind'
          ],
          explanation: 'Erzeugung und Verbrauch müssen im Netz jederzeit '
              'übereinstimmen.'),
      _K.fact('Kernspaltung', 'Aufspaltung schwerer Atomkerne',
          explanation: 'Grundlage heutiger Kernkraftwerke; es bleibt '
              'langlebiger radioaktiver Abfall.'),
      _K.question('Was ist Kernfusion?', 'Das Verschmelzen leichter Atomkerne',
          distractors: <String>[
            'Das Spalten schwerer Kerne',
            'Das Verbrennen von Wasserstoff',
            'Das Laden eines Akkus'
          ],
          explanation: 'Sie treibt die Sonne an; technisch nutzbar ist sie '
              'bisher nicht.'),
      _K.fact('Treibhauseffekt',
          'Rückhalt von Wärme durch Gase in der Atmosphäre',
          explanation: 'Ohne ihn wäre die Erde unbewohnbar kalt — der Mensch '
              'verstärkt ihn.'),
      _K.question('Wie hoch ist der Wirkungsgrad eines Kohlekraftwerks etwa?',
          'Rund 40 Prozent',
          distractors: <String>[
            'Rund 90 Prozent',
            'Rund 10 Prozent',
            'Fast 100 Prozent'
          ],
          explanation: 'Der Rest entweicht als Abwärme.'),
      _K.fact('Dämmung', 'Schicht, die den Wärmeverlust eines Gebäudes senkt',
          explanation: 'Die günstigste Energie ist die, die gar nicht '
              'gebraucht wird.'),
    ],
  ),
];
