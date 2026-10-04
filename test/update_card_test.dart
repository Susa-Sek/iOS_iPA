import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/state/update_check.dart';
import 'package:ipa_testing_github_action/widgets/update_card.dart';

import 'update_check_test.dart' show FakeUpdateBackend;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const Release v390 = Release(
    version: '3.9.0',
    apkUrl: 'https://example.invalid/app.apk',
    pageUrl: 'https://example.invalid/releases',
  );

  Widget rahmen(UpdateService? service) {
    const Widget karte = Scaffold(body: Center(child: UpdateCard()));
    return MaterialApp(
      home: service == null
          ? karte
          : UpdateScope(service: service, child: karte),
    );
  }

  testWidgets('ohne neuere Version nimmt sie keinen Platz',
      (WidgetTester tester) async {
    final UpdateService service =
        UpdateService(backend: FakeUpdateBackend(release: v390));
    await service.check(laufendeVersion: '3.9.0');

    await tester.pumpWidget(rahmen(service));
    expect(find.byType(Card), findsNothing);
    expect(tester.getSize(find.byType(UpdateCard)), Size.zero);
  });

  testWidgets('ohne Update-Dienst bleibt sie still',
      (WidgetTester tester) async {
    // Der Fall im Test und in jedem Baum ohne UpdateScope: keine Zusicherung,
    // die umfällt, sondern nichts.
    await tester.pumpWidget(rahmen(null));
    expect(tester.getSize(find.byType(UpdateCard)), Size.zero);
  });

  testWidgets('mit neuerer Version steht sie da', (WidgetTester tester) async {
    final UpdateService service =
        UpdateService(backend: FakeUpdateBackend(release: v390));
    await service.check(laufendeVersion: '3.8.0');

    await tester.pumpWidget(rahmen(service));
    expect(find.text('Version 3.9.0 ist da'), findsOneWidget);
    expect(find.text('Dein Lernstand bleibt erhalten.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Holen'), findsOneWidget);
  });

  testWidgets('„Holen" öffnet die Adresse', (WidgetTester tester) async {
    final List<Uri> geoeffnet = <Uri>[];
    final UpdateService service = UpdateService(
      backend: FakeUpdateBackend(release: v390),
      opener: (Uri uri) async {
        geoeffnet.add(uri);
        return true;
      },
    );
    await service.check(laufendeVersion: '3.8.0');

    await tester.pumpWidget(rahmen(service));
    await tester.tap(find.text('Holen'));
    await tester.pumpAndSettle();
    expect(geoeffnet.single.toString(), 'https://example.invalid/app.apk');
  });

  testWidgets('lässt sich die Adresse nicht öffnen, sagt sie es',
      (WidgetTester tester) async {
    final UpdateService service = UpdateService(
      backend: FakeUpdateBackend(release: v390),
      opener: (Uri uri) async => false,
    );
    await service.check(laufendeVersion: '3.8.0');

    await tester.pumpWidget(rahmen(service));
    await tester.tap(find.text('Holen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('GitHub-Seite'), findsOneWidget);
  });

  testWidgets('bei 320 px und 150 % Schrift läuft nichts über',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final UpdateService service =
        UpdateService(backend: FakeUpdateBackend(release: v390));
    await service.check(laufendeVersion: '3.8.0');

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
      child: rahmen(service),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Holen'), findsOneWidget);
  });
}
