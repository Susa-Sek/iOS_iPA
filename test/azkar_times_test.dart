import 'package:adhan/adhan.dart' show Madhab;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/models/azkar.dart';
import 'package:ipa_testing_github_action/state/prayer_times.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const Ort berlin = Ort('Berlin', 52.5200, 13.4050);

  AzkarFenster fenster(
    AzkarTime welche,
    DateTime tag, {
    Madhab madhab = Madhab.shafi,
    int versatz = 20,
  }) =>
      azkarFenster(
        welche: welche,
        tag: tag,
        ort: berlin,
        madhab: madhab,
        versatzMinuten: versatz,
      );

  group('Die Fenster liegen richtig', () {
    for (final (String name, DateTime tag) in <(String, DateTime)>[
      ('Hochsommer', DateTime(2026, 6, 21)),
      ('Mittwinter', DateTime(2026, 12, 21)),
      ('Tagundnachtgleiche', DateTime(2026, 3, 20)),
    ]) {
      test('$name: morgens zwischen Fajr und Sonnenaufgang', () {
        final AzkarFenster f = fenster(AzkarTime.morgens, tag);
        expect(f.beginn.isBefore(f.ende), isTrue);
        expect(f.faellig.isBefore(f.beginn), isFalse);
        expect(f.faellig.isBefore(f.ende), isTrue);
        expect(f.faellig.day, tag.day, reason: 'nicht über Mitternacht');
      });

      test('$name: abends zwischen ʿAsr und Maġrib', () {
        final AzkarFenster f = fenster(AzkarTime.abends, tag);
        expect(f.beginn.isBefore(f.ende), isTrue);
        expect(f.faellig.isBefore(f.beginn), isFalse);
        expect(f.faellig.isBefore(f.ende), isTrue);
      });

      test('$name: morgens liegt vor abends', () {
        expect(
          fenster(AzkarTime.morgens, tag)
              .faellig
              .isBefore(fenster(AzkarTime.abends, tag).faellig),
          isTrue,
        );
      });
    }

    test('im Sommer liegt Fajr nicht auf dem Vortag', () {
      // Der Grund für HighLatitudeRule.seventh_of_the_night: Mit der Vorgabe
      // der Bibliothek fiel Fajr am 21. Juni auf den 20. Juni, 23:08 — eine
      // darauf geplante Erinnerung läge in der Vergangenheit und entfiele
      // den ganzen Sommer über still.
      for (int tag = 1; tag <= 30; tag++) {
        final DateTime d = DateTime(2026, 6, tag);
        final AzkarFenster f = fenster(AzkarTime.morgens, d);
        expect(f.beginn.day, tag, reason: '21.06.+$tag Fajr am falschen Tag');
        expect(f.faellig.day, tag, reason: 'Erinnerung am falschen Tag');
      }
    });

    test('die Zeiten wandern übers Jahr', () {
      // Der ganze Grund für die Kopplung an die Gebetszeiten: eine feste
      // Uhrzeit wäre im Dezember falsch oder im Juni.
      final DateTime juni =
          fenster(AzkarTime.morgens, DateTime(2026, 6, 21)).faellig;
      final DateTime dezember =
          fenster(AzkarTime.morgens, DateTime(2026, 12, 21)).faellig;
      final int unterschied =
          (dezember.hour * 60 + dezember.minute) - (juni.hour * 60 + juni.minute);
      expect(unterschied.abs(), greaterThan(90),
          reason: 'zwischen Sommer und Winter liegen Stunden');
    });
  });

  group('Der Maḏhab verschiebt den Abend', () {
    test('Ḥanafī beginnt später als Šāfiʿī', () {
      final DateTime shafi =
          fenster(AzkarTime.abends, DateTime(2026, 6, 21)).beginn;
      final DateTime hanafi = fenster(AzkarTime.abends, DateTime(2026, 6, 21),
              madhab: Madhab.hanafi)
          .beginn;
      expect(hanafi.isAfter(shafi), isTrue);
    });

    test('der Morgen bleibt davon unberührt', () {
      expect(
        fenster(AzkarTime.morgens, DateTime(2026, 6, 21)).beginn,
        fenster(AzkarTime.morgens, DateTime(2026, 6, 21),
                madhab: Madhab.hanafi)
            .beginn,
      );
    });
  });

  group('Der Versatz', () {
    test('verschiebt die Erinnerung nach hinten', () {
      final DateTime ohne =
          fenster(AzkarTime.morgens, DateTime(2026, 3, 20), versatz: 0).faellig;
      final DateTime mit =
          fenster(AzkarTime.morgens, DateTime(2026, 3, 20), versatz: 30).faellig;
      expect(mit.difference(ohne), const Duration(minutes: 30));
    });

    test('wird ins Fenster geklemmt', () {
      // Ein großzügiger Versatz darf die Morgen-Azkar nicht hinter den
      // Sonnenaufgang schieben — dann wäre die Zeit dafür schon vorbei.
      final AzkarFenster f =
          fenster(AzkarTime.morgens, DateTime(2026, 6, 21), versatz: 120);
      expect(f.faellig.isBefore(f.ende), isTrue);
      expect(f.faellig.difference(f.ende).inMinutes.abs(),
          greaterThanOrEqualTo(5),
          reason: 'etwas Luft vor dem Ende');
    });
  });

  group('Ohne eingestellten Ort', () {
    test('gibt es keine Zeit statt einer geratenen', () async {
      final AzkarSettings settings = AzkarSettings();
      await settings.load();
      expect(settings.eingerichtet, isFalse);
      expect(settings.fenster(AzkarTime.morgens, DateTime(2026, 6, 21)), isNull);
      expect(settings.jetztDran(DateTime(2026, 6, 21, 7)), isNull);
    });
  });

  group('Die Einstellungen halten', () {
    test('Ort, Methode, Maḏhab, Versatz und Stufe überleben den Neustart',
        () async {
      final AzkarSettings erst = AzkarSettings();
      await erst.load();
      await erst.setOrt(berlin);
      await erst.setMethode(AzkarMethod.turkey);
      await erst.setMadhab(Madhab.hanafi);
      await erst.setVersatz(45);
      await erst.setLevel(AzkarLevel.vollstaendig);

      final AzkarSettings wieder = AzkarSettings();
      await wieder.load();
      expect(wieder.ort, berlin);
      expect(wieder.methode, AzkarMethod.turkey);
      expect(wieder.madhab, Madhab.hanafi);
      expect(wieder.versatz, 45);
      expect(wieder.level, AzkarLevel.vollstaendig);
      expect(wieder.eingerichtet, isTrue);
    });

    test('frisch ist die Stufe „Voll" und kein Ort gesetzt', () async {
      final AzkarSettings settings = AzkarSettings();
      await settings.load();
      expect(settings.level, AzkarLevel.voll);
      expect(settings.ort, isNull);
      expect(settings.versatz, AzkarSettings.defaultVersatz);
    });

    test('ein unsinniger Versatz wird eingefangen', () async {
      final AzkarSettings settings = AzkarSettings();
      await settings.load();
      await settings.setVersatz(-30);
      expect(settings.versatz, 0);
      await settings.setVersatz(9999);
      expect(settings.versatz, 120);
    });
  });

  group('Welche Hälfte gerade dran ist', () {
    test('innerhalb des Morgenfensters: morgens', () async {
      final AzkarSettings settings = AzkarSettings();
      await settings.load();
      await settings.setOrt(berlin);

      final AzkarFenster f = fenster(AzkarTime.morgens, DateTime(2026, 6, 21));
      final DateTime mitten = f.beginn
          .add(Duration(minutes: f.ende.difference(f.beginn).inMinutes ~/ 2));
      expect(settings.jetztDran(mitten), AzkarTime.morgens);
    });

    test('mitten in der Nacht: keine von beiden', () async {
      final AzkarSettings settings = AzkarSettings();
      await settings.load();
      await settings.setOrt(berlin);
      expect(settings.jetztDran(DateTime(2026, 12, 21, 2)), isNull);
    });
  });
}
