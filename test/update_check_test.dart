import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/state/update_check.dart';

/// Ein Backend ohne Netz: liefert, was der Test vorgibt, und zählt mit.
class FakeUpdateBackend implements UpdateBackend {
  FakeUpdateBackend({this.release});

  Release? release;
  int aufrufe = 0;

  @override
  Future<Release?> latest() async {
    aufrufe++;
    return release;
  }
}

/// Ein Backend, das scheitert — der häufigste Fall unterwegs.
class KaputtesBackend implements UpdateBackend {
  @override
  Future<Release?> latest() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const Release v390 = Release(
    version: '3.9.0',
    apkUrl: 'https://example.invalid/app.apk',
    pageUrl: 'https://example.invalid/releases/v3.9.0',
  );

  group('Welche Version ist neuer', () {
    test('Zahl für Zahl, nicht Zeichen für Zeichen', () {
      // Der Fehler, den jeder Versionsvergleich einmal macht: zeichenweise
      // ist „3.10.0" kleiner als „3.9.0", weil „1" vor „9" kommt.
      expect(istNeuer('3.9.0', '3.10.0'), isTrue);
      expect(istNeuer('3.10.0', '3.9.0'), isFalse);
    });

    test('die üblichen Fälle', () {
      expect(istNeuer('3.8.0', '3.8.1'), isTrue);
      expect(istNeuer('3.8.0', '3.9.0'), isTrue);
      expect(istNeuer('3.8.0', '4.0.0'), isTrue);
      expect(istNeuer('3.8.1', '3.8.0'), isFalse);
      expect(istNeuer('3.8.0', '3.8.0'), isFalse, reason: 'gleich ist nicht neuer');
    });

    test('ein führendes v und der Baustand stören nicht', () {
      expect(istNeuer('3.8.0', 'v3.9.0'), isTrue);
      expect(istNeuer('3.8.0+19', '3.9.0+20'), isTrue);
      expect(istNeuer('3.8.0+19', '3.8.0+20'), isFalse,
          reason: 'derselbe Stand, nur neu gebaut');
    });

    test('fehlende Stellen zählen als null', () {
      expect(istNeuer('3.8', '3.8.1'), isTrue);
      expect(istNeuer('3.8.1', '3.8'), isFalse);
      expect(istNeuer('4', '3.9.9'), isFalse);
    });

    test('Unsinn meldet kein Update', () {
      // Lieber kein Hinweis als ein falscher.
      expect(istNeuer('3.8.0', ''), isFalse);
      expect(istNeuer('', '3.9.0'), isFalse);
      expect(istNeuer('3.8.0', 'abc'), isFalse);
      expect(istNeuer('abc', 'def'), isFalse);
      expect(istNeuer('3.8.0', 'v'), isFalse);
    });
  });

  group('Die Antwort von GitHub lesen', () {
    test('nimmt die APK aus den Anhängen', () {
      final Release? r = releaseFromJson(<String, dynamic>{
        'tag_name': 'v3.9.0',
        'html_url': 'https://example.invalid/releases/v3.9.0',
        'assets': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Taeglich-Klueger-v3.9.0.aab',
            'browser_download_url': 'https://example.invalid/a.aab',
          },
          <String, dynamic>{
            'name': 'Taeglich-Klueger-v3.9.0.apk',
            'browser_download_url': 'https://example.invalid/a.apk',
          },
        ],
      });
      expect(r?.version, '3.9.0', reason: 'ohne führendes v');
      expect(r?.apkUrl, 'https://example.invalid/a.apk',
          reason: 'die APK, nicht das App Bundle');
    });

    test('ohne APK bleibt die Seite', () {
      final Release? r = releaseFromJson(<String, dynamic>{
        'tag_name': 'v3.9.0',
        'html_url': 'https://example.invalid/releases/v3.9.0',
        'assets': <Object>[],
      });
      expect(r?.apkUrl, 'https://example.invalid/releases/v3.9.0');
    });

    test('ohne Kennung kein Release', () {
      expect(releaseFromJson(<String, dynamic>{}), isNull);
      expect(releaseFromJson(<String, dynamic>{'tag_name': ''}), isNull);
    });
  });

  group('Der Dienst', () {
    test('meldet eine neuere Version', () async {
      final FakeUpdateBackend backend = FakeUpdateBackend(release: v390);
      final UpdateService service = UpdateService(backend: backend);

      await service.check(laufendeVersion: '3.8.0');
      expect(service.neuere?.version, '3.9.0');
    });

    test('schweigt bei derselben Version', () async {
      final UpdateService service =
          UpdateService(backend: FakeUpdateBackend(release: v390));
      await service.check(laufendeVersion: '3.9.0');
      expect(service.neuere, isNull);
    });

    test('schweigt, wenn die Abfrage scheitert', () async {
      // Offline, Repository nicht öffentlich, GitHub weg — alles derselbe
      // Fall: keine Karte, keine Fehlermeldung.
      final UpdateService service = UpdateService(backend: KaputtesBackend());
      await service.check(laufendeVersion: '3.8.0');
      expect(service.neuere, isNull);
    });

    test('fragt höchstens einmal am Tag', () async {
      final FakeUpdateBackend backend = FakeUpdateBackend(release: v390);
      DateTime jetzt = DateTime(2026, 10, 4, 8);
      final UpdateService service =
          UpdateService(backend: backend, clock: () => jetzt);

      await service.check(laufendeVersion: '3.8.0');
      await service.check(laufendeVersion: '3.8.0');
      await service.check(laufendeVersion: '3.8.0');
      expect(backend.aufrufe, 1);

      jetzt = DateTime(2026, 10, 5, 8);
      await service.check(laufendeVersion: '3.8.0');
      expect(backend.aufrufe, 2, reason: 'am nächsten Tag wieder');
    });

    test('die Bremse überlebt einen Neustart', () async {
      final FakeUpdateBackend backend = FakeUpdateBackend(release: v390);
      final DateTime jetzt = DateTime(2026, 10, 4, 8);
      await UpdateService(backend: backend, clock: () => jetzt)
          .check(laufendeVersion: '3.8.0');
      expect(backend.aufrufe, 1);

      // Neue Instanz, wie nach einem Neustart der App.
      await UpdateService(backend: backend, clock: () => jetzt)
          .check(laufendeVersion: '3.8.0');
      expect(backend.aufrufe, 1);
    });

    test('„force" fragt trotzdem', () async {
      final FakeUpdateBackend backend = FakeUpdateBackend(release: v390);
      final DateTime jetzt = DateTime(2026, 10, 4, 8);
      final UpdateService service =
          UpdateService(backend: backend, clock: () => jetzt);
      await service.check(laufendeVersion: '3.8.0');
      await service.check(laufendeVersion: '3.8.0', force: true);
      expect(backend.aufrufe, 2);
    });

    test('„Holen" öffnet die APK-Adresse', () async {
      final List<Uri> geoeffnet = <Uri>[];
      final UpdateService service = UpdateService(
        backend: FakeUpdateBackend(release: v390),
        opener: (Uri uri) async {
          geoeffnet.add(uri);
          return true;
        },
      );
      await service.check(laufendeVersion: '3.8.0');

      expect(await service.holen(), isTrue);
      expect(geoeffnet.single.toString(), 'https://example.invalid/app.apk');
    });

    test('ohne neuere Version gibt es nichts zu holen', () async {
      final UpdateService service = UpdateService(
        backend: FakeUpdateBackend(release: v390),
        opener: (Uri uri) async => true,
      );
      await service.check(laufendeVersion: '3.9.0');
      expect(await service.holen(), isFalse);
    });
  });
}
