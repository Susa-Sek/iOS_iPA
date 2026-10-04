import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/azkar.dart';

/// Ein Ort mit Koordinaten.
///
/// **Ohne Standortberechtigung.** Man stellt seinen Ort einmal ein, und
/// danach rechnet die App offline. Eine Berechtigung, die bei jedem Start
/// nachfragt, wäre für eine Zahl, die sich im Jahr um Minuten verschiebt,
/// unangemessen — und ein Fehlerfall mehr.
@immutable
class Ort {
  const Ort(this.name, this.lat, this.lon);

  final String name;
  final double lat;
  final double lon;

  Coordinates get coordinates => Coordinates(lat, lon);

  @override
  bool operator ==(Object other) =>
      other is Ort && other.name == name && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(name, lat, lon);

  @override
  String toString() => name;
}

/// Eine Auswahl größerer Städte — der schnelle Weg. Wer woanders wohnt,
/// trägt Breite und Länge von Hand ein.
const List<Ort> kOrte = <Ort>[
  Ort('Berlin', 52.5200, 13.4050),
  Ort('Hamburg', 53.5511, 9.9937),
  Ort('München', 48.1351, 11.5820),
  Ort('Köln', 50.9375, 6.9603),
  Ort('Frankfurt am Main', 50.1109, 8.6821),
  Ort('Stuttgart', 48.7758, 9.1829),
  Ort('Düsseldorf', 51.2277, 6.7735),
  Ort('Leipzig', 51.3397, 12.3731),
  Ort('Dortmund', 51.5136, 7.4653),
  Ort('Essen', 51.4556, 7.0116),
  Ort('Bremen', 53.0793, 8.8017),
  Ort('Dresden', 51.0504, 13.7373),
  Ort('Hannover', 52.3759, 9.7320),
  Ort('Nürnberg', 49.4521, 11.0767),
  Ort('Duisburg', 51.4344, 6.7623),
  Ort('Bochum', 51.4818, 7.2162),
  Ort('Wuppertal', 51.2562, 7.1508),
  Ort('Bielefeld', 52.0302, 8.5325),
  Ort('Bonn', 50.7374, 7.0982),
  Ort('Münster', 51.9607, 7.6261),
  Ort('Mannheim', 49.4875, 8.4660),
  Ort('Karlsruhe', 49.0069, 8.4037),
  Ort('Augsburg', 48.3705, 10.8978),
  Ort('Wiesbaden', 50.0782, 8.2398),
  Ort('Mönchengladbach', 51.1805, 6.4428),
  Ort('Gelsenkirchen', 51.5177, 7.0857),
  Ort('Braunschweig', 52.2689, 10.5268),
  Ort('Kiel', 54.3233, 10.1228),
  Ort('Wien', 48.2082, 16.3738),
  Ort('Zürich', 47.3769, 8.5417),
];

/// Die Berechnungsmethoden, die hier zur Wahl stehen.
///
/// Nicht alle, die `adhan` kennt — nur die, die in Europa vorkommen. Eine
/// Liste mit zwanzig Einträgen wäre keine Wahl, sondern eine Zumutung.
enum AzkarMethod {
  mwl('mwl', 'Muslim World League', CalculationMethod.muslim_world_league),
  turkey('turkey', 'Diyanet (Türkei)', CalculationMethod.turkey),
  egypt('egypt', 'Ägyptische Behörde', CalculationMethod.egyptian),
  karachi('karachi', 'Karatschi', CalculationMethod.karachi),
  isna('isna', 'ISNA (Nordamerika)', CalculationMethod.north_america);

  const AzkarMethod(this.id, this.label, this.method);

  final String id;
  final String label;
  final CalculationMethod method;

  static AzkarMethod byId(String id) =>
      values.firstWhere((AzkarMethod m) => m.id == id, orElse: () => mwl);
}

/// Wann die Azkar fällig sind und wie lange ihr Fenster offen steht.
@immutable
class AzkarFenster {
  const AzkarFenster({
    required this.faellig,
    required this.beginn,
    required this.ende,
  });

  /// Der Zeitpunkt der Erinnerung.
  final DateTime faellig;

  /// Von wann bis wann die Azkar dieser Hälfte gesprochen werden.
  final DateTime beginn;
  final DateTime ende;

  bool enthaelt(DateTime moment) =>
      !moment.isBefore(beginn) && moment.isBefore(ende);
}

/// Das Fenster einer Tageshälfte an einem Tag — rein, damit ein Test es ohne
/// Gerät und ohne Speicher nachrechnen kann.
///
/// * **Morgens** nach Fajr, bis zum Sonnenaufgang.
/// * **Abends** nach ʿAsr, bis zum Maġrib.
///
/// Der Versatz wird **ins Fenster geklemmt**: Ein großzügig eingestellter
/// Versatz darf die Erinnerung nicht hinter den Sonnenaufgang schieben, sonst
/// käme sie, wenn die Zeit für die Morgen-Azkar schon vorbei ist.
AzkarFenster azkarFenster({
  required AzkarTime welche,
  required DateTime tag,
  required Ort ort,
  AzkarMethod methode = AzkarMethod.mwl,
  Madhab madhab = Madhab.shafi,
  int versatzMinuten = 20,
}) {
  final CalculationParameters parameter = methode.method.getParameters()
    ..madhab = madhab
    // **Gemessen, nicht geraten.** In Berlin geht die Sonne im Sommer nie
    // 18° unter den Horizont — Fajr ist nach der reinen Winkelrechnung
    // undefiniert, und `adhan` behilft sich mit einer Regel. Die Vorgabe
    // (`middle_of_the_night`) legt Fajr am 21. Juni auf den **20. Juni,
    // 23:08** — einen Tag zu früh. Eine so geplante Erinnerung läge in der
    // Vergangenheit und fiele wochenlang still aus.
    //
    //   middle_of_the_night   fajr = 20.06. 23:08   (falscher Tag)
    //   twilight_angle        fajr = 21.06. 00:34
    //   seventh_of_the_night  fajr = 21.06. 01:42   ← gewählt
    //
    // `seventh_of_the_night` ist die übliche Regel für hohe Breiten und
    // hält Fajr auf dem richtigen Tag. Im Winter rechnen alle drei gleich.
    ..highLatitudeRule = HighLatitudeRule.seventh_of_the_night;
  final PrayerTimes zeiten = PrayerTimes(
    ort.coordinates,
    DateComponents(tag.year, tag.month, tag.day),
    parameter,
  );

  final (DateTime beginn, DateTime ende) = switch (welche) {
    AzkarTime.morgens => (zeiten.fajr, zeiten.sunrise),
    AzkarTime.abends => (zeiten.asr, zeiten.maghrib),
  };

  DateTime faellig = beginn.add(Duration(minutes: versatzMinuten));
  // Mindestens fünf Minuten Luft vor dem Ende — eine Erinnerung in der
  // letzten Minute hilft niemandem. In hohen Breiten kann das Fenster
  // kürzer als der Versatz sein; dann gilt der Beginn.
  final DateTime spaetestens = ende.subtract(const Duration(minutes: 5));
  if (faellig.isAfter(spaetestens)) {
    faellig = spaetestens.isBefore(beginn) ? beginn : spaetestens;
  }

  return AzkarFenster(faellig: faellig, beginn: beginn, ende: ende);
}

/// Ort, Methode, Maḏhab, Versatz und Stufe.
class AzkarSettings extends ChangeNotifier {
  AzkarSettings({SharedPreferences? preferences}) : _prefs = preferences;

  /// Nicht umbenennen — siehe test/naming_test.dart.
  static const String settingsKey = 'arabisch_lernen.azkar.settings.v1';

  static const int defaultVersatz = 20;

  SharedPreferences? _prefs;

  Ort? _ort;
  AzkarMethod _methode = AzkarMethod.mwl;
  Madhab _madhab = Madhab.shafi;
  int _versatz = defaultVersatz;
  AzkarLevel _level = AzkarLevel.voll;

  /// `null`, solange kein Ort eingestellt ist. Dann gibt es **keine**
  /// Azkar-Erinnerung — lieber keine als eine zur falschen Zeit.
  Ort? get ort => _ort;
  AzkarMethod get methode => _methode;
  Madhab get madhab => _madhab;
  int get versatz => _versatz;
  AzkarLevel get level => _level;
  bool get eingerichtet => _ort != null;

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final String? roh = _prefs?.getString(settingsKey);
      if (roh != null && roh.isNotEmpty) _lies(roh);
    } catch (error) {
      debugPrint('Azkar-Einstellungen nicht lesbar: $error');
    }
    notifyListeners();
  }

  void _lies(String roh) {
    final Object? json = jsonDecode(roh);
    if (json is! Map) return;
    final Object? name = json['ort'];
    final Object? lat = json['lat'];
    final Object? lon = json['lon'];
    if (name is String && lat is num && lon is num) {
      _ort = Ort(name, lat.toDouble(), lon.toDouble());
    }
    _methode = AzkarMethod.byId((json['methode'] as String?) ?? 'mwl');
    _madhab = json['madhab'] == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    _versatz = (json['versatz'] as num?)?.toInt() ?? defaultVersatz;
    _level = AzkarLevel.byId((json['level'] as String?) ?? '') ?? AzkarLevel.voll;
  }

  Future<void> _schreibe() async {
    notifyListeners();
    try {
      await _prefs?.setString(
        settingsKey,
        jsonEncode(<String, dynamic>{
          if (_ort case final Ort o) ...<String, dynamic>{
            'ort': o.name,
            'lat': o.lat,
            'lon': o.lon,
          },
          'methode': _methode.id,
          'madhab': _madhab == Madhab.hanafi ? 'hanafi' : 'shafi',
          'versatz': _versatz,
          'level': _level.id,
        }),
      );
    } catch (error) {
      debugPrint('Azkar-Einstellungen nicht speicherbar: $error');
    }
  }

  Future<void> setOrt(Ort? ort) async {
    _ort = ort;
    await _schreibe();
  }

  Future<void> setMethode(AzkarMethod methode) async {
    _methode = methode;
    await _schreibe();
  }

  Future<void> setMadhab(Madhab madhab) async {
    _madhab = madhab;
    await _schreibe();
  }

  Future<void> setVersatz(int minuten) async {
    _versatz = minuten.clamp(0, 120);
    await _schreibe();
  }

  Future<void> setLevel(AzkarLevel level) async {
    _level = level;
    await _schreibe();
  }

  /// Das Fenster einer Tageshälfte, oder `null` ohne eingestellten Ort.
  AzkarFenster? fenster(AzkarTime welche, DateTime tag) {
    final Ort? o = _ort;
    if (o == null) return null;
    return azkarFenster(
      welche: welche,
      tag: tag,
      ort: o,
      methode: _methode,
      madhab: _madhab,
      versatzMinuten: _versatz,
    );
  }

  /// Welche Hälfte gerade dran ist — `null` außerhalb beider Fenster.
  AzkarTime? jetztDran(DateTime moment) {
    for (final AzkarTime t in AzkarTime.values) {
      if (fenster(t, moment)?.enthaelt(moment) ?? false) return t;
    }
    return null;
  }
}

/// Macht die Azkar-Einstellungen im Baum verfügbar.
class AzkarSettingsScope extends InheritedNotifier<AzkarSettings> {
  const AzkarSettingsScope({
    super.key,
    required AzkarSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AzkarSettings of(BuildContext context) {
    final AzkarSettingsScope? scope =
        context.dependOnInheritedWidgetOfExactType<AzkarSettingsScope>();
    assert(scope != null, 'No AzkarSettingsScope found in the widget tree');
    return scope!.notifier!;
  }
}
