import 'package:flutter/material.dart';

import '../../models/vocabulary.dart';

/// Kurzform, damit die Listen lesbar bleiben — wie in `vocabulary_more.dart`.
typedef _K = VocabEntry;

/// Allgemeinbildung: acht Themen, die man einmal gehört haben sollte.
///
/// **Regel für alle Wissensdaten:** keine Frage, deren Antwort sich ändern
/// kann. „Wer ist Bundeskanzler?" gehört in den Bereich „Heute", nicht in den
/// festen Bestand. Wo eine Zahl unvermeidlich ist, steht der Stand dabei.
const List<VocabCategory> kAllgemeinbildung = <VocabCategory>[
  VocabCategory(
    id: 'w_geografie',
    name: 'Geografie',
    icon: Icons.public,
    color: Color(0xFF2E7D8A),
    softColor: Color(0x242E7D8A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Kontinent', 'Zusammenhängende große Landmasse',
          explanation: 'Üblich ist die Einteilung in sieben: Afrika, '
              'Antarktis, Asien, Australien, Europa, Nord- und Südamerika.'),
      _K.question('Welcher Fluss ist der längste Europas?', 'Wolga',
          distractors: <String>['Donau', 'Rhein', 'Dnepr'],
          explanation:
              'Rund 3.530 Kilometer; sie mündet ins Kaspische Meer.'),
      _K.question('Welcher Ozean ist der größte?', 'Pazifik',
          distractors: <String>['Atlantik', 'Indischer Ozean', 'Südpolarmeer'],
          explanation: 'Er bedeckt etwa ein Drittel der Erdoberfläche.'),
      _K.question('Wie viele Bundesländer hat Deutschland?', '16',
          distractors: <String>['12', '14', '18'],
          explanation: 'Seit der Wiedervereinigung 1990.'),
      _K.fact('Äquator', 'Linie des größten Erdumfangs',
          explanation: 'Rund 40.075 Kilometer lang, auf halbem Weg zwischen '
              'den Polen.'),
      _K.question('Welches ist das flächengrößte Land der Erde?', 'Russland',
          distractors: <String>['Kanada', 'China', 'USA'],
          explanation: 'Rund 17 Millionen Quadratkilometer — mehr als die '
              'gesamte Fläche Südamerikas.'),
      _K.fact('Hauptstadt der Schweiz', 'Bern',
          explanation: 'Bern ist Bundesstadt; formal kennt die Schweiz keine '
              'Hauptstadt.'),
      _K.question('Welches Gebirge gilt als Grenze zwischen Europa und Asien?',
          'Der Ural',
          distractors: <String>['Der Kaukasus', 'Die Alpen', 'Die Karpaten'],
          explanation: 'Eine Übereinkunft, keine natürliche Trennung — die '
              'beiden Erdteile hängen zusammen.'),
      _K.fact('Sahara', 'Größte Trockenwüste der Erde, in Nordafrika',
          explanation: 'Etwa so groß wie die Vereinigten Staaten.'),
      _K.question('An welches Meer grenzt Ägypten im Osten?', 'Rotes Meer',
          distractors: <String>[
            'Schwarzes Meer',
            'Kaspisches Meer',
            'Totes Meer'
          ],
          explanation: 'Im Norden liegt das Mittelmeer, dazwischen der '
              'Sueskanal.'),
      _K.fact('Zeitzone', 'Gebiet mit gleicher gesetzlicher Uhrzeit',
          explanation: 'Die Erde ist in 24 Zonen um den Nullmeridian '
              'eingeteilt; Ländergrenzen verbiegen sie.'),
      _K.question('Welcher See ist der tiefste der Erde?', 'Baikalsee',
          distractors: <String>[
            'Kaspisches Meer',
            'Titicacasee',
            'Tanganjikasee'
          ],
          explanation: 'Über 1.600 Meter tief, in Sibirien — er enthält rund '
              'ein Fünftel des flüssigen Süßwassers der Erde.'),
      _K.fact('Golfstrom', 'Warme Meeresströmung im Atlantik',
          explanation: 'Er macht Nordwesteuropa milder, als es auf dieser '
              'Breite zu erwarten wäre.'),
      _K.question('Welcher Berg ist der höchste der Erde?', 'Mount Everest',
          distractors: <String>['K2', 'Mont Blanc', 'Kilimandscharo'],
          explanation: 'Rund 8.849 Meter über dem Meeresspiegel, im Himalaya.'),
      _K.fact('Mittelmeer', 'Binnenmeer zwischen Europa, Afrika und Asien',
          explanation: 'Mit dem Atlantik nur durch die schmale Straße von '
              'Gibraltar verbunden.'),
    ],
  ),
  VocabCategory(
    id: 'w_geschichte',
    name: 'Geschichte',
    icon: Icons.history_edu,
    color: Color(0xFF8A6E2E),
    softColor: Color(0x248A6E2E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('In welchem Jahr fiel die Berliner Mauer?', '1989',
          distractors: <String>['1987', '1990', '1991'],
          explanation: 'Am 9. November 1989; die Wiedervereinigung folgte am '
              '3. Oktober 1990.'),
      _K.question('Wann begann der Erste Weltkrieg?', '1914',
          distractors: <String>['1912', '1918', '1939'],
          explanation: 'Er dauerte bis 1918 und kostete rund 17 Millionen '
              'Menschen das Leben.'),
      _K.question('Wann endete der Zweite Weltkrieg in Europa?', '1945',
          distractors: <String>['1944', '1946', '1943'],
          explanation: 'Mit der bedingungslosen Kapitulation am 8. Mai 1945.'),
      _K.fact('Gutenberg', 'Erfinder des Buchdrucks mit beweglichen Lettern',
          explanation: 'Um 1450 in Mainz — erstmals ließ sich Wissen in '
              'großer Zahl vervielfältigen.'),
      _K.question('Wer veröffentlichte die 95 Thesen?', 'Martin Luther',
          distractors: <String>[
            'Johannes Calvin',
            'Thomas Müntzer',
            'Philipp Melanchthon'
          ],
          explanation: '1517 in Wittenberg — der Beginn der Reformation.'),
      _K.fact('Französische Revolution', 'Umsturz der Ständeordnung ab 1789',
          explanation: 'Aus ihr stammt die Losung Freiheit, Gleichheit, '
              'Brüderlichkeit.'),
      _K.question('Welches Reich errichtete den Limes in Germanien?',
          'Das Römische Reich',
          distractors: <String>[
            'Das Frankenreich',
            'Das Byzantinische Reich',
            'Das Osmanische Reich'
          ],
          explanation: 'Ab dem 1. Jahrhundert sicherte er die Nordgrenze; '
              'Reste stehen bis heute.'),
      _K.fact('Industrielle Revolution',
          'Übergang zur maschinellen Produktion ab dem 18. Jahrhundert',
          explanation: 'Sie begann in England mit Dampfmaschine und '
              'Textilindustrie.'),
      _K.question('In welchem Jahr wurde das Grundgesetz verkündet?', '1949',
          distractors: <String>['1945', '1919', '1955'],
          explanation: 'Am 23. Mai 1949 — als Provisorium gedacht, bis heute '
              'in Kraft.'),
      _K.fact('Weimarer Republik', 'Deutsche Demokratie von 1919 bis 1933',
          explanation: 'Benannt nach dem Tagungsort der '
              'Nationalversammlung.'),
      _K.question('Wer war die erste Frau mit einem Nobelpreis?',
          'Marie Curie',
          distractors: <String>[
            'Rosalind Franklin',
            'Lise Meitner',
            'Ada Lovelace'
          ],
          explanation: '1903 in Physik, 1911 in Chemie — sie erhielt ihn als '
              'erster Mensch zweimal.'),
      _K.fact('Kalter Krieg',
          'Machtkampf zwischen den USA und der Sowjetunion nach 1945',
          explanation: 'Ohne direkten Krieg der beiden, aber mit '
              'Stellvertreterkriegen; er endete um 1990.'),
      _K.question('Wann landeten erstmals Menschen auf dem Mond?', '1969',
          distractors: <String>['1961', '1972', '1957'],
          explanation: 'Apollo 11, am 20. Juli 1969.'),
      _K.fact('Hanse',
          'Bündnis norddeutscher Kaufleute und Städte im Mittelalter',
          explanation: 'Sie beherrschte jahrhundertelang den Handel in Nord- '
              'und Ostsee.'),
      _K.question('In welchem Jahrhundert ging das Weströmische Reich unter?',
          '5. Jahrhundert',
          distractors: <String>[
            '3. Jahrhundert',
            '7. Jahrhundert',
            '9. Jahrhundert'
          ],
          explanation: '476 wurde der letzte weströmische Kaiser abgesetzt; '
              'das Oströmische Reich bestand noch tausend Jahre.'),
    ],
  ),
  VocabCategory(
    id: 'w_natur',
    name: 'Naturwissenschaft',
    icon: Icons.science_outlined,
    color: Color(0xFF3B6E3B),
    softColor: Color(0x243B6E3B),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Wie lautet die chemische Formel von Wasser?', 'H₂O',
          distractors: <String>['CO₂', 'O₂', 'H₂O₂'],
          explanation: 'Zwei Wasserstoffatome an einem Sauerstoffatom.'),
      _K.fact('Photosynthese', 'Pflanzen bauen aus Licht, Wasser und CO₂ Zucker',
          explanation: 'Dabei entsteht Sauerstoff — die Grundlage fast aller '
              'Nahrungsketten.'),
      _K.question('Welches Gas brauchen Menschen zum Atmen?', 'Sauerstoff',
          distractors: <String>['Stickstoff', 'Kohlendioxid', 'Wasserstoff'],
          explanation: 'Luft besteht zu rund 21 Prozent aus Sauerstoff und zu '
              '78 Prozent aus Stickstoff.'),
      _K.fact('Schwerkraft', 'Anziehung zwischen Massen',
          explanation: 'Sie hält die Erde auf ihrer Bahn und uns auf dem '
              'Boden.'),
      _K.question('Bei wie viel Grad Celsius gefriert Wasser?', '0 °C',
          distractors: <String>['4 °C', '−10 °C', '100 °C'],
          explanation: 'Bei normalem Luftdruck; auf Bergen siedet es früher, '
              'gefriert aber weiter bei null.'),
      _K.fact('Atom', 'Kleinster Baustein eines chemischen Elements',
          explanation: 'Ein Kern aus Protonen und Neutronen, umgeben von '
              'Elektronen.'),
      _K.question('Was misst die Einheit Volt?', 'Elektrische Spannung',
          distractors: <String>['Stromstärke', 'Widerstand', 'Leistung'],
          explanation: 'Stromstärke misst man in Ampere, Leistung in Watt.'),
      _K.fact('Dichte', 'Masse geteilt durch Volumen',
          explanation: 'Deshalb schwimmt Holz auf Wasser und Eisen nicht.'),
      _K.question('Welches Element hat das Symbol Fe?', 'Eisen',
          distractors: <String>['Fluor', 'Francium', 'Phosphor'],
          explanation: 'Vom lateinischen ferrum.'),
      _K.fact('Energieerhaltung',
          'Energie geht nicht verloren, sie wandelt sich um',
          explanation: 'Ein Grundsatz der Physik — ein Perpetuum mobile ist '
              'deshalb unmöglich.'),
      _K.question('Wie schnell ist Licht im Vakuum ungefähr?', '300.000 km/s',
          distractors: <String>['30.000 km/s', '3.000 km/s', '3 Mio. km/s'],
          explanation: 'Genau 299.792.458 Meter je Sekunde — eine '
              'Naturkonstante.'),
      _K.fact('DNA', 'Träger der Erbinformation in Zellen',
          explanation: '1953 als Doppelhelix beschrieben.'),
      _K.question('Was entsteht beim Verbrennen von Kohlenstoff?',
          'Kohlendioxid',
          distractors: <String>['Sauerstoff', 'Methan', 'Ozon'],
          explanation: 'CO₂ — das wichtigste vom Menschen freigesetzte '
              'Treibhausgas.'),
      _K.fact('Katalysator', 'Stoff, der eine Reaktion beschleunigt',
          explanation: 'Er verbraucht sich dabei nicht. Im Auto wandelt er '
              'Abgase in weniger schädliche Stoffe um.'),
      _K.question('Welcher Stoff macht Blätter grün?', 'Chlorophyll',
          distractors: <String>['Hämoglobin', 'Melanin', 'Karotin'],
          explanation: 'Es fängt das Sonnenlicht für die Photosynthese ein.'),
    ],
  ),
  VocabCategory(
    id: 'w_koerper',
    name: 'Körper & Medizin',
    icon: Icons.favorite_outline,
    color: Color(0xFF8A2E4A),
    softColor: Color(0x248A2E4A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Wie viele Knochen hat ein erwachsener Mensch etwa?', '206',
          distractors: <String>['150', '300', '412'],
          explanation: 'Neugeborene haben mehr; einige Knochen wachsen später '
              'zusammen.'),
      _K.fact('Herz', 'Muskel, der das Blut durch den Körper pumpt',
          explanation: 'In Ruhe schlägt er etwa 60- bis 80-mal je Minute.'),
      _K.question('Welches Organ bildet die Galle?', 'Die Leber',
          distractors: <String>[
            'Die Niere',
            'Die Milz',
            'Die Bauchspeicheldrüse'
          ],
          explanation: 'Die Nieren filtern dagegen das Blut und bilden Harn.'),
      _K.fact('Antibiotikum', 'Mittel gegen bakterielle Infektionen',
          explanation: 'Gegen Viren wirkt es nicht — bei einer Erkältung '
              'hilft es deshalb meist nicht.'),
      _K.question('Woraus besteht Blut überwiegend?', 'Aus Plasma',
          distractors: <String>[
            'Aus roten Blutkörperchen',
            'Aus Lymphe',
            'Aus Salzwasser'
          ],
          explanation: 'Rund 55 Prozent Plasma, der Rest sind Blutzellen.'),
      _K.fact('Impfung', 'Training des Immunsystems mit einem harmlosen Reiz',
          explanation: 'Der Körper bildet Abwehrstoffe, bevor er dem Erreger '
              'wirklich begegnet.'),
      _K.question('Wie viele Zähne hat ein Erwachsener mit Weisheitszähnen?',
          '32',
          distractors: <String>['20', '28', '36'],
          explanation: 'Das Milchgebiss hat 20 Zähne.'),
      _K.fact('Puls', 'Fühlbare Druckwelle des Blutes in den Arterien',
          explanation: 'Er entspricht dem Herzschlag.'),
      _K.question('Welches Vitamin bildet der Körper im Sonnenlicht?',
          'Vitamin D',
          distractors: <String>['Vitamin C', 'Vitamin B12', 'Vitamin K'],
          explanation: 'Es ist wichtig für die Knochen; im Winter reicht das '
              'Licht in unseren Breiten oft nicht.'),
      _K.fact('Immunsystem', 'Abwehr des Körpers gegen Krankheitserreger',
          explanation: 'Es merkt sich Erreger, denen es schon begegnet ist.'),
      _K.question('Wo werden Nährstoffe hauptsächlich aufgenommen?',
          'Im Dünndarm',
          distractors: <String>[
            'Im Magen',
            'Im Dickdarm',
            'In der Speiseröhre'
          ],
          explanation: 'Der Dickdarm entzieht dem Rest vor allem Wasser.'),
      _K.fact('Blutdruck', 'Druck des Blutes auf die Gefäßwände',
          explanation: 'Angegeben in zwei Werten, etwa 120 zu 80.'),
      _K.question('Welcher Teil des Gehirns steuert die Atmung?',
          'Der Hirnstamm',
          distractors: <String>['Die Großhirnrinde', 'Das Kleinhirn', 'Das Auge'],
          explanation: 'Deshalb atmet man auch im Schlaf weiter.'),
      _K.fact('Placebo', 'Scheinbehandlung ohne Wirkstoff',
          explanation: 'Sie kann trotzdem wirken — deshalb wird in Studien '
              'dagegen verglichen.'),
      _K.question('Wie viel Prozent des Körpergewichts ist grob Wasser?',
          'Etwa 60 %',
          distractors: <String>['Etwa 20 %', 'Etwa 40 %', 'Etwa 90 %'],
          explanation: 'Bei Säuglingen mehr, im Alter weniger.'),
    ],
  ),
  VocabCategory(
    id: 'w_kunst',
    name: 'Kunst & Literatur',
    icon: Icons.palette_outlined,
    color: Color(0xFF6A4C93),
    softColor: Color(0x246A4C93),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Wer schrieb „Faust"?', 'Johann Wolfgang von Goethe',
          distractors: <String>[
            'Friedrich Schiller',
            'Heinrich Heine',
            'Thomas Mann'
          ],
          explanation: 'Der erste Teil erschien 1808.'),
      _K.fact('Roman', 'Längere erzählende Dichtung in Prosa',
          explanation: 'Von Novelle und Kurzgeschichte vor allem durch den '
              'Umfang abgegrenzt.'),
      _K.question('Wer malte die „Mona Lisa"?', 'Leonardo da Vinci',
          distractors: <String>['Michelangelo', 'Raffael', 'Tizian'],
          explanation: 'Das Bild hängt im Louvre in Paris.'),
      _K.fact('Lyrik', 'Dichtung in Versen, meist gebunden und knapp',
          explanation: 'Neben Epik und Dramatik eine der drei Gattungen.'),
      _K.question('In welcher Stadt lebte Franz Kafka?', 'Prag',
          distractors: <String>['Wien', 'Berlin', 'Budapest'],
          explanation: 'Er schrieb auf Deutsch und arbeitete dort als '
              'Versicherungsbeamter.'),
      _K.fact('Impressionismus',
          'Malerei des flüchtigen Lichteindrucks, ab etwa 1870',
          explanation: 'Benannt nach Monets Bild „Impression, soleil '
              'levant".'),
      _K.question('Wer komponierte die Neunte mit der „Ode an die Freude"?',
          'Ludwig van Beethoven',
          distractors: <String>[
            'Johannes Brahms',
            'Franz Schubert',
            'Joseph Haydn'
          ],
          explanation: 'Ihr Thema ist heute die Hymne Europas.'),
      _K.fact('Metapher', 'Bild, das eine Sache durch eine andere benennt',
          explanation: '„Ein Herz aus Stein" sagt nichts über Steine.'),
      _K.question('Wer schrieb „Romeo und Julia"?', 'William Shakespeare',
          distractors: <String>[
            'Christopher Marlowe',
            'Molière',
            'Lord Byron'
          ],
          explanation: 'Um 1595 entstanden.'),
      _K.fact('Barock', 'Epoche von etwa 1600 bis 1750, prunkvoll und bewegt',
          explanation: 'In der Musik Bach und Händel, in der Baukunst '
              'geschwungene Formen.'),
      _K.question('Welche Kunstrichtung begründete Picasso mit?',
          'Den Kubismus',
          distractors: <String>[
            'Den Surrealismus',
            'Den Expressionismus',
            'Die Pop-Art'
          ],
          explanation: 'Gegenstände werden aus mehreren Blickwinkeln zugleich '
              'gezeigt.'),
      _K.fact('Drama', 'Für die Bühne geschriebenes Werk in Dialogen',
          explanation: 'Es zeigt Handlung, statt sie zu erzählen.'),
      _K.question('Wer schrieb „Die Blechtrommel"?', 'Günter Grass',
          distractors: <String>[
            'Heinrich Böll',
            'Siegfried Lenz',
            'Max Frisch'
          ],
          explanation: '1959 erschienen; Grass erhielt 1999 den Nobelpreis '
              'für Literatur.'),
      _K.fact('Perspektive', 'Darstellung von Raumtiefe auf der Fläche',
          explanation: 'In der Renaissance mathematisch durchgearbeitet.'),
      _K.question('Was ist ein Sonett?', 'Ein Gedicht aus 14 Versen',
          distractors: <String>[
            'Ein Stück in fünf Akten',
            'Ein Lied ohne Worte',
            'Eine Kurzgeschichte'
          ],
          explanation: 'Meist zwei Vierzeiler und zwei Dreizeiler.'),
    ],
  ),
  VocabCategory(
    id: 'w_mathe',
    name: 'Mathematik & Zahlen',
    icon: Icons.calculate_outlined,
    color: Color(0xFF2E5C8A),
    softColor: Color(0x242E5C8A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Wie viel ergibt 7 × 8?', '56',
          distractors: <String>['54', '48', '63'],
          explanation: 'Der Wert aus dem Einmaleins, der am häufigsten '
              'danebengeht.'),
      _K.fact('Primzahl',
          'Zahl über 1, die nur durch 1 und sich selbst teilbar ist',
          explanation: '2, 3, 5, 7, 11 — die 2 ist die einzige gerade.'),
      _K.question('Wie groß ist die Winkelsumme im Dreieck?', '180 Grad',
          distractors: <String>['90 Grad', '360 Grad', '270 Grad'],
          explanation: 'In der Ebene; auf einer Kugel gilt das nicht.'),
      _K.fact('Prozent', 'Anteil von hundert',
          explanation: '20 Prozent von 50 sind 10.'),
      _K.question('Wofür steht π ungefähr?', '3,14',
          distractors: <String>['2,72', '1,62', '3,41'],
          explanation: 'Das Verhältnis von Umfang zu Durchmesser eines '
              'Kreises.'),
      _K.fact('Bruch', 'Zahl als Verhältnis zweier ganzer Zahlen',
          explanation: '3/4 heißt: drei von vier gleichen Teilen.'),
      _K.question('Was ist der Median einer Zahlenreihe?', 'Der mittlere Wert',
          distractors: <String>[
            'Der Durchschnitt',
            'Der häufigste Wert',
            'Die Spannweite'
          ],
          explanation: 'Anders als der Durchschnitt ist er unempfindlich '
              'gegen einzelne Ausreißer.'),
      _K.fact('Satz des Pythagoras', 'a² + b² = c² im rechtwinkligen Dreieck',
          explanation: 'c ist die Seite gegenüber dem rechten Winkel.'),
      _K.question('Wie viel Prozent sind ein Viertel?', '25 %',
          distractors: <String>['20 %', '40 %', '14 %'],
          explanation: '1 geteilt durch 4 ergibt 0,25.'),
      _K.fact('Wahrscheinlichkeit',
          'Maß für die Erwartung eines Ereignisses, zwischen 0 und 1',
          explanation: 'Ein Münzwurf: 0,5 für Kopf.'),
      _K.question('Wie viele Nullen hat eine Milliarde?', 'Neun',
          distractors: <String>['Sechs', 'Zwölf', 'Fünfzehn'],
          explanation: 'Eine Million hat sechs, eine Billion zwölf.'),
      _K.fact('Exponentielles Wachstum',
          'Wachstum um einen festen Faktor je Schritt',
          explanation: 'Es wirkt lange harmlos und wird dann sehr schnell '
              'sehr groß.'),
      _K.question('Was ergibt 2 hoch 10?', '1024',
          distractors: <String>['100', '512', '2048'],
          explanation: 'Deshalb sind 1024 Byte ein Kibibyte.'),
      _K.fact('Durchschnitt', 'Summe geteilt durch Anzahl',
          explanation: 'Auch arithmetisches Mittel genannt.'),
      _K.question('Wie viele Teiler hat eine Primzahl?', 'Genau zwei',
          distractors: <String>[
            'Genau einen',
            'Genau drei',
            'Beliebig viele'
          ],
          explanation: '1 und sich selbst — deshalb ist die 1 keine '
              'Primzahl.'),
    ],
  ),
  VocabCategory(
    id: 'w_astronomie',
    name: 'Astronomie',
    icon: Icons.nightlight_outlined,
    color: Color(0xFF3A3A6E),
    softColor: Color(0x243A3A6E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Welcher Planet ist der Sonne am nächsten?', 'Merkur',
          distractors: <String>['Venus', 'Mars', 'Erde'],
          explanation: 'Venus ist der zweitnächste.'),
      _K.fact('Lichtjahr', 'Strecke, die Licht in einem Jahr zurücklegt',
          explanation: 'Rund 9,5 Billionen Kilometer — ein Maß für Länge, '
              'nicht für Zeit.'),
      _K.question('Wie viele Planeten hat das Sonnensystem?', 'Acht',
          distractors: <String>['Neun', 'Sieben', 'Zehn'],
          explanation: 'Pluto gilt seit 2006 als Zwergplanet.'),
      _K.fact('Mondphasen', 'Wechselnder beleuchteter Anteil des Mondes',
          explanation: 'Ein voller Zyklus dauert rund 29,5 Tage.'),
      _K.question('Was ist die Sonne?', 'Ein Stern',
          distractors: <String>['Ein Planet', 'Ein Komet', 'Ein Nebel'],
          explanation: 'Ein durchschnittlicher Stern — nur sehr viel näher '
              'als alle anderen.'),
      _K.fact('Schwarzes Loch',
          'Massekonzentration, aus der kein Licht entkommt',
          explanation: 'Im Zentrum der meisten Galaxien sitzt ein sehr '
              'großes.'),
      _K.question('Welcher Planet ist der größte im Sonnensystem?', 'Jupiter',
          distractors: <String>['Saturn', 'Neptun', 'Uranus'],
          explanation: 'Er hat mehr Masse als alle anderen Planeten '
              'zusammen.'),
      _K.fact('Galaxie', 'System aus Milliarden Sternen, Gas und Staub',
          explanation: 'Unsere heißt Milchstraße.'),
      _K.question('Warum gibt es Jahreszeiten?', 'Weil die Erdachse geneigt ist',
          distractors: <String>[
            'Weil die Erde der Sonne mal näher ist',
            'Weil die Sonne schwankt',
            'Weil der Mond die Erde kippt'
          ],
          explanation: 'Die Neigung beträgt rund 23,5 Grad.'),
      _K.fact('Sonnenfinsternis', 'Der Mond schiebt sich vor die Sonne',
          explanation: 'Bei einer Mondfinsternis liegt dagegen die Erde '
              'dazwischen.'),
      _K.question('Wie lange braucht Licht von der Sonne zur Erde?',
          'Etwa 8 Minuten',
          distractors: <String>[
            'Etwa 8 Sekunden',
            'Etwa 1 Stunde',
            'Etwa 1 Tag'
          ],
          explanation: 'Die Entfernung beträgt rund 150 Millionen '
              'Kilometer.'),
      _K.fact('Urknall', 'Modell vom heißen, dichten Anfang des Universums',
          explanation: 'Vor rund 13,8 Milliarden Jahren.'),
      _K.question('Welcher Planet heißt der Rote Planet?', 'Mars',
          distractors: <String>['Venus', 'Merkur', 'Jupiter'],
          explanation: 'Eisenoxid im Staub gibt ihm die Farbe.'),
      _K.fact('Komet', 'Eis- und Staubkörper mit Schweif nahe der Sonne',
          explanation: 'Der Schweif zeigt immer von der Sonne weg.'),
      _K.question('Was hält die Planeten auf ihrer Bahn?',
          'Die Schwerkraft der Sonne',
          distractors: <String>[
            'Der Sonnenwind',
            'Das Magnetfeld',
            'Der Luftdruck'
          ],
          explanation: 'Ohne sie flögen sie geradeaus davon.'),
    ],
  ),
  VocabCategory(
    id: 'w_biologie',
    name: 'Tiere & Pflanzen',
    icon: Icons.pets_outlined,
    color: Color(0xFF4C7A2E),
    softColor: Color(0x244C7A2E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Welches ist das größte Tier der Erde?', 'Der Blauwal',
          distractors: <String>[
            'Der Afrikanische Elefant',
            'Der Weiße Hai',
            'Die Giraffe'
          ],
          explanation: 'Bis zu 30 Meter lang — das größte Tier, das je '
              'gelebt hat.'),
      _K.fact('Säugetier', 'Wirbeltier, das seine Jungen mit Milch säugt',
          explanation: 'Auch Wale und Fledermäuse gehören dazu.'),
      _K.question('Wie viele Beine hat eine Spinne?', 'Acht',
          distractors: <String>['Sechs', 'Zehn', 'Zwölf'],
          explanation: 'Insekten haben sechs — Spinnen sind keine Insekten.'),
      _K.fact('Bestäubung', 'Übertragung von Pollen zwischen Blüten',
          explanation: 'Ohne Insekten fiele ein großer Teil der Ernte aus.'),
      _K.question('Welcher Vogel kann nicht fliegen?', 'Der Pinguin',
          distractors: <String>['Der Albatros', 'Der Kolibri', 'Der Storch'],
          explanation: 'Seine Flügel sind zu Flossen umgebaut.'),
      _K.fact('Nahrungskette', 'Reihe, in der einer den anderen frisst',
          explanation: 'Am Anfang stehen Pflanzen, die Licht nutzen.'),
      _K.question('Warum wirft ein Laubbaum im Herbst die Blätter ab?',
          'Um im Winter weniger Wasser zu verlieren',
          distractors: <String>[
            'Um Platz für neue zu schaffen',
            'Weil die Blätter zu schwer werden',
            'Um Tiere zu füttern'
          ],
          explanation: 'Gefrorener Boden gibt kaum Wasser her.'),
      _K.fact('Symbiose', 'Zusammenleben zum Nutzen beider Arten',
          explanation: 'Eine Flechte ist Pilz und Alge zugleich.'),
      _K.question('Welches Insekt bildet Staaten mit einer Königin?',
          'Die Honigbiene',
          distractors: <String>[
            'Der Marienkäfer',
            'Die Libelle',
            'Der Schmetterling'
          ],
          explanation: 'Auch Ameisen und Termiten leben in Staaten.'),
      _K.fact('Winterschlaf', 'Ruhezustand mit stark gesenktem Stoffwechsel',
          explanation: 'Igel und Murmeltiere überstehen so die Zeit ohne '
              'Nahrung.'),
      _K.question('Was ist ein Pilz, den man im Wald sammelt?',
          'Der Fruchtkörper',
          distractors: <String>[
            'Die Wurzel',
            'Die ganze Pflanze',
            'Ein Blatt'
          ],
          explanation: 'Der eigentliche Pilz ist ein weit verzweigtes '
              'Geflecht im Boden.'),
      _K.fact('Wirbellose', 'Tiere ohne Wirbelsäule',
          explanation: 'Sie stellen weit über 90 Prozent aller Tierarten.'),
      _K.question('Welches Säugetier legt Eier?', 'Das Schnabeltier',
          distractors: <String>[
            'Der Delfin',
            'Das Gürteltier',
            'Die Fledermaus'
          ],
          explanation: 'Es lebt in Australien; nur ganz wenige Säugetiere '
              'legen Eier.'),
      _K.fact('Jahresring', 'Zuwachsring im Holz eines Baumes',
          explanation: 'Ein Ring je Jahr — daran lässt sich das Alter '
              'ablesen.'),
      _K.question('Was fressen Große Pandas fast ausschließlich?', 'Bambus',
          distractors: <String>['Fisch', 'Gras', 'Früchte'],
          explanation: 'Obwohl ihr Verdauungssystem das eines Fleischfressers '
              'ist — deshalb müssen sie sehr viel davon fressen.'),
    ],
  ),
];
