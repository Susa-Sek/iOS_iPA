import 'package:flutter/material.dart';

import '../../models/vocabulary.dart';

typedef _K = VocabEntry;

/// Politik, Wirtschaft, Gesellschaft — die Regeln, nach denen das
/// Zusammenleben organisiert ist.
///
/// Hier gilt die Regel gegen veränderliche Antworten besonders: Wer welches
/// Amt innehat, gehört in den Bereich „Heute". Was hier steht, ändert sich
/// nur, wenn Gesetze geändert werden.
const List<VocabCategory> kGesellschaft = <VocabCategory>[
  VocabCategory(
    id: 'w_staat',
    name: 'Staat & Verfassung',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF2E4A8A),
    softColor: Color(0x242E4A8A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Wie heißt die Verfassung Deutschlands?', 'Grundgesetz',
          distractors: <String>[
            'Bundesverfassung',
            'Reichsverfassung',
            'Staatsvertrag'
          ],
          explanation: 'In Kraft seit dem 23. Mai 1949.'),
      _K.fact('Artikel 1 des Grundgesetzes',
          'Die Würde des Menschen ist unantastbar',
          explanation: 'Er steht bewusst an erster Stelle und darf nicht '
              'geändert werden.'),
      _K.question('Welche drei Gewalten kennt der Rechtsstaat?',
          'Gesetzgebung, Regierung, Rechtsprechung',
          distractors: <String>[
            'Bund, Länder, Gemeinden',
            'Partei, Presse, Polizei',
            'Volk, Adel, Klerus'
          ],
          explanation: 'Sie sollen einander begrenzen, statt sich zu '
              'ergänzen.'),
      _K.fact('Gewaltenteilung',
          'Aufteilung der Staatsmacht auf getrennte Organe',
          explanation: 'Damit keine Stelle allein entscheidet.'),
      _K.question('Wer wählt den Bundeskanzler?', 'Der Bundestag',
          distractors: <String>[
            'Das Volk direkt',
            'Der Bundesrat',
            'Der Bundespräsident'
          ],
          explanation: 'Der Bundespräsident schlägt vor und ernennt danach.'),
      _K.fact('Bundesrat', 'Vertretung der Länder im Bund',
          explanation: 'Bei Gesetzen, die die Länder betreffen, muss er '
              'zustimmen.'),
      _K.question('Wie lang ist eine Wahlperiode des Bundestages?',
          'Vier Jahre',
          distractors: <String>['Fünf Jahre', 'Drei Jahre', 'Sechs Jahre'],
          explanation: 'Vorgezogene Wahlen sind nur unter engen Bedingungen '
              'möglich.'),
      _K.fact('Föderalismus',
          'Aufteilung staatlicher Aufgaben auf Bund und Länder',
          explanation: 'Schule und Polizei sind in Deutschland Sache der '
              'Länder.'),
      _K.question('Wer ist Staatsoberhaupt in Deutschland?',
          'Der Bundespräsident',
          distractors: <String>[
            'Der Bundeskanzler',
            'Der Bundestagspräsident',
            'Der Ratspräsident'
          ],
          explanation: 'Das Amt ist vor allem repräsentativ.'),
      _K.fact('Bundesverfassungsgericht',
          'Gericht, das Gesetze am Grundgesetz misst',
          explanation: 'Es sitzt in Karlsruhe und kann Gesetze für nichtig '
              'erklären.'),
      _K.question('Was kennzeichnet eine parlamentarische Demokratie?',
          'Die Regierung braucht das Vertrauen des Parlaments',
          distractors: <String>[
            'Das Volk stimmt über jedes Gesetz ab',
            'Der Präsident regiert allein',
            'Die Gerichte bestimmen die Regierung'
          ],
          explanation: 'Im Unterschied zur Präsidialdemokratie.'),
      _K.fact('Koalition', 'Bündnis von Parteien zur Mehrheitsbildung',
          explanation: 'Nötig, wenn keine Partei allein die Mehrheit hat.'),
      _K.question('Für welches deutsche Amt gilt eine Amtszeitbegrenzung?',
          'Für den Bundespräsidenten',
          distractors: <String>[
            'Für den Bundeskanzler',
            'Für Abgeordnete',
            'Für Richter'
          ],
          explanation: 'Höchstens zwei Amtszeiten von je fünf Jahren.'),
      _K.fact('Volkssouveränität', 'Alle Staatsgewalt geht vom Volke aus',
          explanation: 'Artikel 20 des Grundgesetzes.'),
      _K.question('Wer kann das Grundgesetz ändern?',
          'Bundestag und Bundesrat mit Zweidrittelmehrheit',
          distractors: <String>[
            'Der Bundestag allein mit einfacher Mehrheit',
            'Das Volk in einer Volksabstimmung',
            'Das Bundesverfassungsgericht durch Urteil',
          ],
          explanation: 'Menschenwürde und Bundesstaat sind der Änderung ganz '
              'entzogen.'),
    ],
  ),
  VocabCategory(
    id: 'w_wahlen',
    name: 'Wahlen & Parteien',
    icon: Icons.how_to_vote_outlined,
    color: Color(0xFF6E2E8A),
    softColor: Color(0x246E2E8A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Ab welchem Alter darf man den Bundestag wählen?', '18',
          distractors: <String>['16', '21', '25'],
          explanation: 'Für Europawahlen gilt in Deutschland seit 2024 die '
              'Grenze von 16 Jahren.'),
      _K.fact('Erststimme', 'Stimme für eine Person im Wahlkreis',
          explanation: 'Die Zweitstimme entscheidet über die Stärke der '
              'Parteien.'),
      _K.question('Welche Stimme bestimmt die Sitzverteilung im Bundestag?',
          'Die Zweitstimme',
          distractors: <String>[
            'Die Erststimme',
            'Beide zu gleichen Teilen',
            'Die Briefwahlstimme'
          ],
          explanation: 'Die Erststimme entscheidet nur über den Sieger im '
              'Wahlkreis.'),
      _K.fact('Fünf-Prozent-Hürde', 'Mindestanteil für den Einzug ins Parlament',
          explanation: 'Sie soll Zersplitterung verhindern.'),
      _K.question('Was bedeutet „geheime Wahl"?',
          'Niemand darf erfahren, wie man gewählt hat',
          distractors: <String>[
            'Niemand erfährt vorher die Kandidaten',
            'Niemand erfährt das Ergebnis vor Schluss',
            'Niemand darf über die Wahl berichten',
          ],
          explanation: 'Einer der fünf Wahlrechtsgrundsätze.'),
      _K.fact('Opposition', 'Parteien im Parlament, die nicht regieren',
          explanation: 'Ihre Aufgabe ist Kontrolle — und ein sichtbares '
              'Gegenangebot.'),
      _K.question('Wie oft finden Europawahlen statt?', 'Alle fünf Jahre',
          distractors: <String>[
            'Alle vier Jahre',
            'Alle sechs Jahre',
            'Alle drei Jahre'
          ],
          explanation: 'In allen Mitgliedstaaten innerhalb weniger Tage.'),
      _K.fact('Wahlbeteiligung', 'Anteil der Wahlberechtigten, die abstimmen',
          explanation: 'Sie sagt etwas über das Vertrauen in das Verfahren '
              'aus.'),
      _K.question('Was ist ein Volksentscheid?',
          'Eine Abstimmung des Volkes über eine Sachfrage',
          distractors: <String>[
            'Eine Wahl des Volkes zwischen Kandidaten',
            'Eine Befragung des Volkes ohne Bindung',
            'Eine Abstimmung des Parlaments über ein Gesetz',
          ],
          explanation: 'Auf Bundesebene ist er in Deutschland kaum '
              'vorgesehen.'),
      _K.fact('Fraktion', 'Zusammenschluss von Abgeordneten einer Partei',
          explanation: 'Sie bündelt Redezeit, Anträge und Ausschusssitze.'),
      _K.question('Was heißt „allgemeine Wahl"?',
          'Alle Bürger ab dem Wahlalter dürfen wählen',
          distractors: <String>[
            'Alle Themen werden gewählt',
            'Alle Parteien treten an',
            'Alle Länder wählen zugleich'
          ],
          explanation: 'Unabhängig von Einkommen, Geschlecht oder Bildung.'),
      _K.fact('Wahlkreis', 'Gebiet, das einen Abgeordneten direkt wählt',
          explanation: 'Deutschland ist in 299 Wahlkreise eingeteilt.'),
      _K.question('Was kennzeichnet eine Verhältniswahl?',
          'Sitze nach Stimmenanteilen',
          distractors: <String>[
            'Sitze nach gewonnenen Wahlkreisen',
            'Sitze nach der Mitgliederzahl der Parteien',
            'Sitze nach der Reihenfolge der Anmeldung',
          ],
          explanation: 'Beim Mehrheitswahlrecht gewinnt je Wahlkreis nur '
              'einer, der Rest der Stimmen verfällt.'),
      _K.fact('Parteiprogramm', 'Schriftlich festgehaltene Ziele einer Partei',
          explanation: 'Es sagt, wofür eine Partei stehen will — nicht, was '
              'sie tun wird.'),
    ],
  ),
  VocabCategory(
    id: 'w_europa',
    name: 'Europa & Welt',
    icon: Icons.language_outlined,
    color: Color(0xFF2E7A8A),
    softColor: Color(0x242E7A8A),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.question('Wie viele Mitgliedstaaten hat die EU?', '27',
          distractors: <String>['25', '28', '30'],
          explanation: 'Seit dem Austritt des Vereinigten Königreichs 2020.'),
      _K.fact('Europäische Union', 'Staatenverbund mit gemeinsamem Binnenmarkt',
          explanation: 'Hervorgegangen aus der Wirtschaftsgemeinschaft der '
              '1950er-Jahre.'),
      _K.question('Was ist der Schengen-Raum?',
          'Ein Gebiet ohne Kontrollen an den Binnengrenzen',
          distractors: <String>[
            'Ein Gebiet mit einer gemeinsamen Währung',
            'Ein Gebiet mit einheitlichen Zöllen nach außen',
            'Ein Gebiet mit gemeinsamer Verteidigung',
          ],
          explanation: 'Er ist nicht deckungsgleich mit der EU.'),
      _K.fact('Euro', 'Gemeinsame Währung eines Teils der EU-Staaten',
          explanation: 'Als Bargeld seit 2002; nicht alle Mitglieder nutzen '
              'ihn.'),
      _K.question('Wo hat das Europäische Parlament seinen Sitz?',
          'In Straßburg',
          distractors: <String>['In Brüssel', 'In Luxemburg', 'In Den Haag'],
          explanation: 'Die Ausschüsse tagen in Brüssel, die Verwaltung sitzt '
              'in Luxemburg.'),
      _K.fact('Vereinte Nationen',
          'Weltweiter Staatenbund für Frieden und Zusammenarbeit',
          explanation: '1945 gegründet, Sitz in New York.'),
      _K.question('Wie viele ständige Mitglieder hat der UN-Sicherheitsrat?',
          'Fünf',
          distractors: <String>['Zehn', 'Drei', 'Fünfzehn'],
          explanation: 'China, Frankreich, Russland, das Vereinigte Königreich '
              'und die USA — jedes mit Vetorecht.'),
      _K.fact('NATO', 'Verteidigungsbündnis in Nordamerika und Europa',
          explanation: 'Der Beistandsfall steht in Artikel 5 des Vertrags.'),
      _K.question('Was regeln die Genfer Konventionen?',
          'Den Schutz von Menschen im Krieg',
          distractors: <String>[
            'Den Schutz von Kulturgütern im Krieg',
            'Den Schutz der Meere vor Verschmutzung',
            'Den Handel zwischen den Staaten',
          ],
          explanation: 'Sie schützen Verwundete, Gefangene und Zivilisten.'),
      _K.fact('Allgemeine Erklärung der Menschenrechte',
          'Erklärung der Vereinten Nationen von 1948',
          explanation: 'Rechtlich nicht bindend, aber Grundlage vieler '
              'verbindlicher Verträge.'),
      _K.question('Was regelt das Pariser Abkommen von 2015?',
          'Die Begrenzung der Erderwärmung',
          distractors: <String>[
            'Die Begrenzung des Welthandels',
            'Die Begrenzung der Atomwaffen',
            'Die Begrenzung der Meeresfischerei',
          ],
          explanation: 'Ziel ist deutlich unter zwei Grad gegenüber '
              'vorindustrieller Zeit.'),
      _K.fact('Binnenmarkt',
          'Freier Verkehr von Waren, Personen, Diensten und Kapital',
          explanation: 'Die vier Grundfreiheiten der EU.'),
      _K.question('Welches Organ schlägt in der EU Gesetze vor?',
          'Die Europäische Kommission',
          distractors: <String>[
            'Das Parlament',
            'Der Rat',
            'Der Gerichtshof'
          ],
          explanation: 'Parlament und Rat beschließen dann gemeinsam.'),
      _K.fact('Entwicklungszusammenarbeit',
          'Unterstützung ärmerer Länder bei Aufbau und Bildung',
          explanation: 'Sie zielt auf Eigenständigkeit, nicht auf '
              'Dauerhilfe.'),
    ],
  ),
  VocabCategory(
    id: 'w_recht',
    name: 'Recht & Rechte',
    icon: Icons.gavel_outlined,
    color: Color(0xFF6E4A2E),
    softColor: Color(0x246E4A2E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Grundrechte', 'Rechte des Einzelnen gegenüber dem Staat',
          explanation: 'Sie stehen in den ersten Artikeln des '
              'Grundgesetzes.'),
      _K.question('Was besagt die Unschuldsvermutung?',
          'Bis zum Urteil gilt jeder als unschuldig',
          distractors: <String>[
            'Der Angeklagte muss schweigen',
            'Das Gericht muss schnell entscheiden',
            'Ohne Geständnis gibt es keine Strafe'
          ],
          explanation: 'Bewiesen werden muss die Schuld, nicht die '
              'Unschuld.'),
      _K.fact('Verjährung', 'Zeitablauf, nach dem ein Anspruch nicht mehr gilt',
          explanation: 'Mord verjährt in Deutschland nicht.'),
      _K.question('Was ist ein Vertrag?',
          'Eine Einigung, aus der Pflichten entstehen',
          distractors: <String>[
            'Ein Versprechen, das nur einen bindet',
            'Ein Angebot, das noch nicht angenommen ist',
            'Ein Beleg über eine gezahlte Summe',
          ],
          explanation: 'Er kann auch mündlich zustande kommen.'),
      _K.fact('Widerrufsrecht',
          'Recht, einen Vertrag ohne Grund rückgängig zu machen',
          explanation: 'Bei Käufen im Netz meist vierzehn Tage.'),
      _K.question('Ab welchem Alter ist man voll geschäftsfähig?', '18',
          distractors: <String>['16', '14', '21'],
          explanation: 'Zwischen 7 und 18 ist man beschränkt '
              'geschäftsfähig.'),
      _K.fact('Urheberrecht', 'Schutz eines Werkes für seinen Schöpfer',
          explanation: 'Es erlischt in Deutschland 70 Jahre nach dem Tod des '
              'Urhebers.'),
      _K.question('Was ist ein Zeuge vor Gericht?',
          'Wer über eigene Wahrnehmungen aussagt',
          distractors: <String>[
            'Wer das Recht auslegt',
            'Wer die Anklage vertritt',
            'Wer den Angeklagten verteidigt'
          ],
          explanation: 'Ein Sachverständiger urteilt dagegen aus '
              'Fachwissen.'),
      _K.fact('Meinungsfreiheit', 'Recht, seine Meinung zu äußern',
          explanation: 'Sie endet dort, wo andere Rechte verletzt werden — '
              'etwa bei Beleidigung oder Volksverhetzung.'),
      _K.question('Wer erhebt in Deutschland öffentliche Anklage?',
          'Die Staatsanwaltschaft',
          distractors: <String>[
            'Die Polizei',
            'Das Gericht',
            'Der Anwalt des Opfers'
          ],
          explanation: 'Die Polizei ermittelt, das Gericht entscheidet.'),
      _K.fact('Gleichheit vor dem Gesetz',
          'Gleiche Regeln für alle, ohne Ansehen der Person',
          explanation: 'Artikel 3 des Grundgesetzes.'),
      _K.question('Was ist Notwehr?',
          'Abwehr eines gegenwärtigen rechtswidrigen Angriffs',
          distractors: <String>[
            'Vergeltung nach einem beendeten Angriff',
            'Abwehr eines erst befürchteten Angriffs',
            'Abwehr eines erlaubten Eingriffs',
          ],
          explanation: 'Sie muss erforderlich sein — und darf nicht über das '
              'Nötige hinausgehen.'),
      _K.fact('Auskunftsrecht',
          'Recht zu erfahren, welche Daten über einen gespeichert sind',
          explanation: 'Jeder kann es bei einem Unternehmen geltend machen.'),
      _K.question('Was bedeutet „im Zweifel für den Angeklagten"?',
          'Bei Zweifeln muss freigesprochen werden',
          distractors: <String>[
            'Bei Zweifeln wird die Strafe gemildert',
            'Bei Zweifeln entscheidet das höhere Gericht',
            'Bei Zweifeln wird das Verfahren vertagt',
          ],
          explanation: 'Lateinisch: in dubio pro reo.'),
    ],
  ),
  VocabCategory(
    id: 'w_wirtschaft',
    name: 'Wirtschaft & Geld',
    icon: Icons.savings_outlined,
    color: Color(0xFF2E8A6E),
    softColor: Color(0x242E8A6E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Inflation', 'Anhaltender Anstieg des allgemeinen Preisniveaus',
          explanation: 'Für dasselbe Geld bekommt man weniger.'),
      _K.question('Was misst das Bruttoinlandsprodukt?',
          'Den Wert aller erzeugten Güter und Dienste',
          distractors: <String>[
            'Das Vermögen eines Landes',
            'Die Summe aller Löhne',
            'Die Staatsverschuldung'
          ],
          explanation: 'Es misst Leistung — nicht Wohlstand und nicht '
              'Verteilung.'),
      _K.fact('Angebot und Nachfrage',
          'Die Kräfte, die auf einem Markt den Preis bilden',
          explanation: 'Steigt die Nachfrage bei gleichem Angebot, steigt der '
              'Preis.'),
      _K.question('Wer legt in der Eurozone den Leitzins fest?',
          'Die Europäische Zentralbank',
          distractors: <String>[
            'Die Bundesbank',
            'Die EU-Kommission',
            'Der Bundestag'
          ],
          explanation: 'Über den Zins wirkt sie auf Kredite und auf die '
              'Inflation.'),
      _K.fact('Zinssatz', 'Preis für geliehenes Geld, in Prozent je Jahr',
          explanation: 'Er gilt für Kredite ebenso wie für Guthaben.'),
      _K.question('Was ist die Rendite?',
          'Der Ertrag im Verhältnis zum Einsatz',
          distractors: <String>[
            'Der eingezahlte Betrag ohne Zinsen',
            'Die Dauer bis zur Auszahlung',
            'Die Gebühr im Verhältnis zum Einsatz',
          ],
          explanation: 'Höhere Rendite geht regelmäßig mit höherem Risiko '
              'einher.'),
      _K.fact('Aktie', 'Anteil an einem Unternehmen',
          explanation: 'Wer sie hält, trägt Gewinn und Verlust mit.'),
      _K.question('Was bedeutet Diversifikation bei der Geldanlage?',
          'Das Risiko auf viele Anlagen verteilen',
          distractors: <String>[
            'Das Geld auf eine einzige Anlage setzen',
            'Das Depot möglichst oft umschichten',
            'Das Risiko durch eine Versicherung abdecken',
          ],
          explanation: 'Nicht alles auf eine Karte — die einfachste Regel der '
              'Geldanlage.'),
      _K.fact('Zinseszins', 'Zinsen, die selbst wieder Zinsen bringen',
          explanation: 'Über lange Zeiträume wirkt er stärker als die '
              'Einzahlung selbst.'),
      _K.question('Wie hoch ist der reguläre Mehrwertsteuersatz in '
          'Deutschland?', '19 %',
          distractors: <String>['16 %', '21 %', '7 %'],
          explanation: '7 Prozent gelten ermäßigt, etwa auf Lebensmittel und '
              'Bücher.'),
      _K.fact('Konjunktur', 'Auf und Ab der Wirtschaftsleistung über die Jahre',
          explanation: 'Aufschwung, Hochphase, Abschwung, Tiefphase.'),
      _K.question('Was ist ein Monopol?',
          'Ein Anbieter beherrscht einen Markt allein',
          distractors: <String>[
            'Ein Käufer beherrscht einen Markt allein',
            'Mehrere Anbieter teilen einen Markt unter sich',
            'Der Staat betreibt ein Unternehmen allein',
          ],
          explanation: 'Ohne Wettbewerb fehlt der Druck auf Preis und '
              'Qualität.'),
      _K.fact('Haushaltsdefizit', 'Ausgaben übersteigen die Einnahmen',
          explanation: 'Die Lücke wird durch neue Schulden gedeckt.'),
      _K.question('Was ist Deflation?', 'Ein anhaltendes Sinken der Preise',
          distractors: <String>[
            'Eine besonders hohe Inflation',
            'Ein Kursverlust',
            'Eine Währungsreform'
          ],
          explanation: 'Klingt gut, lähmt aber Investitionen: Wer wartet, '
              'kauft billiger.'),
      _K.fact('Sparquote', 'Anteil des Einkommens, der nicht ausgegeben wird',
          explanation: 'In Deutschland liegt sie seit Jahren um die zehn '
              'Prozent.'),
    ],
  ),
  VocabCategory(
    id: 'w_arbeit',
    name: 'Arbeit & Soziales',
    icon: Icons.work_outline,
    color: Color(0xFF8A4A6E),
    softColor: Color(0x248A4A6E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Sozialversicherung',
          'Pflichtversicherung gegen große Lebensrisiken',
          explanation: 'Kranken-, Pflege-, Renten-, Arbeitslosen- und '
              'Unfallversicherung.'),
      _K.question('Wie viele Zweige hat die deutsche Sozialversicherung?',
          'Fünf',
          distractors: <String>['Drei', 'Vier', 'Sieben'],
          explanation: 'Kranken, Pflege, Rente, Arbeitslosigkeit, Unfall.'),
      _K.fact('Mindestlohn', 'Gesetzliche Lohnuntergrenze je Stunde',
          explanation: 'In Deutschland seit 2015; die Höhe wird regelmäßig '
              'angepasst.'),
      _K.question('Was ist ein Tarifvertrag?',
          'Vereinbarung zwischen Gewerkschaft und Arbeitgebern',
          distractors: <String>[
            'Vereinbarung zwischen Betrieb und Betriebsrat',
            'Vereinbarung zwischen Arbeitgeber und Beschäftigtem',
            'Vereinbarung zwischen Staat und Gewerkschaft',
          ],
          explanation: 'Er regelt Lohn und Bedingungen für eine ganze '
              'Branche.'),
      _K.fact('Betriebsrat', 'Gewählte Vertretung der Beschäftigten im Betrieb',
          explanation: 'Bei vielen Entscheidungen hat er ein Mitspracherecht.'),
      _K.question('Wie viele Urlaubstage stehen bei einer Fünftagewoche '
          'mindestens zu?', '20',
          distractors: <String>['24', '26', '30'],
          explanation: 'Das Bundesurlaubsgesetz nennt 24 Werktage bei einer '
              'Sechstagewoche.'),
      _K.fact('Kündigungsschutz', 'Regeln, die eine Entlassung erschweren',
          explanation: 'Er greift meist nach sechs Monaten und in größeren '
              'Betrieben.'),
      _K.question('Wie funktioniert die Rente im Umlageverfahren?',
          'Die Beiträge von heute zahlen die Renten von heute',
          distractors: <String>[
            'Die Beiträge von heute werden für später angespart',
            'Die Renten von heute zahlt der Staat aus Steuern',
            'Die Renten von heute zahlen die Arbeitgeber allein',
          ],
          explanation: 'Deshalb hängt sie am Verhältnis von Beitragszahlern '
              'zu Rentnern.'),
      _K.fact('Elternzeit', 'Freistellung zur Betreuung des eigenen Kindes',
          explanation: 'Bis zu drei Jahre je Kind; der Arbeitsplatz bleibt '
              'erhalten.'),
      _K.question('Was ist Kurzarbeit?',
          'Verkürzte Arbeitszeit mit Lohnersatz',
          distractors: <String>[
            'Eine Teilzeitstelle',
            'Unbezahlter Urlaub',
            'Ein befristeter Vertrag'
          ],
          explanation: 'Sie soll Entlassungen in vorübergehenden Krisen '
              'vermeiden.'),
      _K.fact('Arbeitslosengeld', 'Lohnersatz nach dem Verlust der Arbeit',
          explanation: 'Es setzt Beitragszeiten voraus und ist zeitlich '
              'begrenzt.'),
      _K.question('Was bedeutet das Sozialstaatsprinzip?',
          'Der Staat sorgt für sozialen Ausgleich',
          distractors: <String>[
            'Der Staat besitzt alle Betriebe',
            'Alle verdienen gleich viel',
            'Jeder bekommt ein Grundeinkommen'
          ],
          explanation: 'Es steht in Artikel 20 und darf nicht abgeschafft '
              'werden.'),
      _K.fact('Ehrenamt', 'Freiwillige, unbezahlte Arbeit für andere',
          explanation: 'Ohne sie fielen Vereine, Feuerwehr und Hilfsdienste '
              'weitgehend aus.'),
      _K.question('Was ist die Lohnsteuer?',
          'Die Einkommensteuer auf Arbeitslohn',
          distractors: <String>[
            'Eine Steuer der Arbeitgeber',
            'Ein Beitrag an die Gewerkschaft',
            'Ein Sozialversicherungsbeitrag'
          ],
          explanation: 'Der Arbeitgeber führt sie direkt ans Finanzamt ab.'),
    ],
  ),
  VocabCategory(
    id: 'w_medien',
    name: 'Medien & Öffentlichkeit',
    icon: Icons.campaign_outlined,
    color: Color(0xFF8A2E2E),
    softColor: Color(0x248A2E2E),
    script: TextScript.latin,
    entries: <VocabEntry>[
      _K.fact('Pressefreiheit',
          'Recht der Medien, ohne staatliche Lenkung zu berichten',
          explanation: 'Ohne sie lässt sich Macht nicht kontrollieren.'),
      _K.question('Wozu dient ein Impressum?',
          'Es nennt den Verantwortlichen',
          distractors: <String>[
            'Es fasst den Inhalt zusammen',
            'Es nennt die Auflage',
            'Es listet die Werbekunden'
          ],
          explanation: 'Fehlt es, ist niemand greifbar — ein Warnzeichen.'),
      _K.fact('Quelle', 'Herkunft einer Information',
          explanation: 'Wer keine nennt, verlangt Glauben statt Prüfung.'),
      _K.question('Was ist Desinformation?',
          'Absichtlich verbreitete Falschinformation',
          distractors: <String>[
            'Versehentlich verbreitete Falschinformation',
            'Zugespitzt verbreitete Meinung',
            'Erkennbar überzeichnete Satire',
          ],
          explanation: 'Der Unterschied zum Irrtum liegt in der Absicht.'),
      _K.fact('Öffentlich-rechtlicher Rundfunk',
          'Rundfunk, der aus Beiträgen statt aus Werbung lebt',
          explanation: 'Er soll unabhängig vom Markt und vom Staat sein.'),
      _K.question('Was ist eine Filterblase?',
          'Eine Auswahl, die nur Passendes zeigt',
          distractors: <String>[
            'Ein Filter, der Werbung ausblendet',
            'Ein Filter, der unerwünschte Post aussortiert',
            'Eine Auswahl, die zufällig zusammengestellt ist',
          ],
          explanation: 'Programme zeigen bevorzugt, was zur bisherigen '
              'Nutzung passt.'),
      _K.fact('Nachrichtenwert', 'Maß dafür, warum etwas berichtet wird',
          explanation: 'Nähe, Tragweite und Neuheit spielen hinein — '
              'Bedeutung allein reicht nicht.'),
      _K.question('Was unterscheidet Kommentar und Bericht?',
          'Der Kommentar wertet, der Bericht schildert',
          distractors: <String>[
            'Der Kommentar ist länger',
            'Der Bericht steht weiter vorn',
            'Der Kommentar ist anonym'
          ],
          explanation: 'Seriöse Medien machen den Unterschied kenntlich.'),
      _K.fact('Meinungsvielfalt', 'Nebeneinander verschiedener Sichtweisen',
          explanation: 'Wer nur eine Sicht zu hören bekommt, kann sich keine '
              'eigene Meinung bilden.'),
      _K.question('Was prüft man am besten vor dem Teilen einer Meldung?',
          'Wer sie verbreitet und wann sie entstand',
          distractors: <String>[
            'Wie viele sie bereits geteilt haben',
            'Ob sie ein passendes Bild enthält',
            'Ob sie sich flüssig lesen lässt',
          ],
          explanation: 'Alte Meldungen tauchen oft als neue wieder auf.'),
      _K.fact('Zitat', 'Wörtlich übernommene Äußerung mit Quellenangabe',
          explanation: 'Ohne Angabe der Quelle ist es ein Plagiat.'),
      _K.question('Was kennzeichnet eine Verschwörungserzählung?',
          'Sie behauptet einen geheimen Plan hinter Ereignissen',
          distractors: <String>[
            'Sie entsteht aus einem Gerücht ohne Absicht',
            'Sie richtet sich immer gegen die Regierung',
            'Sie verbreitet sich nur in sozialen Netzen',
          ],
          explanation: 'Sie ist meist so gebaut, dass Gegenbeweise als Teil '
              'des Plans gelten — und damit unwiderlegbar.'),
      _K.fact('Informantenschutz',
          'Recht von Journalisten, ihre Quellen zu verschweigen',
          explanation: 'Ohne ihn gäbe es kaum noch Hinweise auf Missstände.'),
      _K.question('Warum sagt die Zahl der Klicks nichts über Wahrheit?',
          'Weil Aufmerksamkeit sich nicht nach Richtigkeit richtet',
          distractors: <String>[
            'Weil Klicks technisch nicht zuverlässig zählbar sind',
            'Weil jede Meldung gleich viele Klicks bekommt',
            'Weil nur bezahlte Meldungen Klicks bekommen',
          ],
          explanation: 'Empörendes verbreitet sich schneller als '
              'Zutreffendes.'),
    ],
  ),
];
