import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/azkar_data.dart';
import 'package:ipa_testing_github_action/models/azkar.dart';
import 'package:ipa_testing_github_action/screens/azkar_screen.dart';
import 'package:ipa_testing_github_action/state/azkar_store.dart';
import 'package:ipa_testing_github_action/state/prayer_times.dart';
import 'package:ipa_testing_github_action/state/speech.dart';
import 'package:ipa_testing_github_action/widgets/speak_button.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const Ort berlin = Ort('Berlin', 52.5200, 13.4050);

  Future<(AzkarStore, AzkarSettings)> dienste({
    Ort? ort = berlin,
    AzkarLevel level = AzkarLevel.leicht,
  }) async {
    final AzkarStore store = AzkarStore();
    await store.load();
    final AzkarSettings settings = AzkarSettings();
    await settings.load();
    if (ort != null) await settings.setOrt(ort);
    await settings.setLevel(level);
    return (store, settings);
  }

  Widget rahmen(AzkarStore store, AzkarSettings settings, {double scale = 1}) =>
      AzkarSettingsScope(
        settings: settings,
        child: AzkarScope(
          store: store,
          child: SpeechScope(
            speaker: Speaker(backend: FakeSpeechBackend()),
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const MaterialApp(home: AzkarScreen()),
            ),
          ),
        ),
      );

  /// Ein hohes Fenster: Eine [ListView] baut nur, was sichtbar ist — Āyat
  /// al-Kursī allein füllt einen Bildschirm, und alles darunter stünde sonst
  /// gar nicht erst im Baum.
  Future<void> oeffne(
    WidgetTester tester, {
    Ort? ort = berlin,
    AzkarLevel level = AzkarLevel.leicht,
    Size groesse = const Size(420, 6000),
    double scale = 1,
  }) async {
    tester.view.physicalSize = groesse;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final (AzkarStore store, AzkarSettings settings) =
        await dienste(ort: ort, level: level);
    await tester.pumpWidget(rahmen(store, settings, scale: scale));
    await tester.pumpAndSettle();
  }

  group('Der Azkar-Reiter', () {
    testWidgets('zeigt beide Hälften zur Auswahl', (WidgetTester tester) async {
      await oeffne(tester);
      expect(find.text('Morgen-Azkar'), findsWidgets);
      expect(find.text('Abend-Azkar'), findsWidgets);
    });

    testWidgets('zeigt Lautschrift, Deutsch und Quelle',
        (WidgetTester tester) async {
      await oeffne(tester);
      expect(find.textContaining('Quran 2:255'), findsOneWidget);
      expect(find.textContaining('al-Buḫārī 6306'), findsOneWidget);
      expect(find.textContaining('Allāhu lā ilāha illā huwa'), findsOneWidget);
    });

    testWidgets('bittet darum, die Texte prüfen zu lassen',
        (WidgetTester tester) async {
      // Das gehört sichtbar in die App, nicht nur in den Quelltext.
      await oeffne(tester, level: AzkarLevel.vollstaendig);
      await tester.scrollUntilVisible(
        find.textContaining('lass sie prüfen'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('lass sie prüfen'), findsOneWidget);
      expect(find.textContaining('Tanzil'), findsOneWidget);
    });
  });

  group('Antippen zählt', () {
    testWidgets('ein Tipp erhöht den Zähler', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final (AzkarStore store, AzkarSettings settings) = await dienste();
      await tester.pumpWidget(rahmen(store, settings));
      await tester.pumpAndSettle();

      final Dhikr dreimal =
          azkarFor(time: AzkarTime.morgens, level: AzkarLevel.leicht)
              .firstWhere((Dhikr d) => d.count == 3);
      expect(find.text('0 / 3'), findsWidgets);

      await tester.tap(find.text('0 / 3').first);
      await tester.pumpAndSettle();
      expect(store.zaehler(AzkarTime.morgens, dreimal), 1);
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('der Kopf zählt mit', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final (AzkarStore store, AzkarSettings settings) = await dienste();
      await tester.pumpWidget(rahmen(store, settings));
      await tester.pumpAndSettle();

      expect(find.text('0 von 5 gesprochen'), findsOneWidget);

      final List<Dhikr> pensum =
          azkarFor(time: AzkarTime.morgens, level: AzkarLevel.leicht);
      final Dhikr einmal = pensum.firstWhere((Dhikr d) => d.count == 1);
      await store.tippe(AzkarTime.morgens, einmal, pensum);
      await tester.pumpAndSettle();
      expect(find.text('1 von 5 gesprochen'), findsOneWidget);
    });
  });

  group('Die Stufe ist keine Mauer', () {
    testWidgets('auf „Leicht" stehen die übrigen unter „Mehr, wenn du magst"',
        (WidgetTester tester) async {
      await oeffne(tester, level: AzkarLevel.leicht);
      expect(find.text('Mehr, wenn du magst'), findsOneWidget);
    });

    testWidgets('auf „Vollständig" gibt es nichts darüber hinaus',
        (WidgetTester tester) async {
      await oeffne(tester, level: AzkarLevel.vollstaendig);
      expect(find.text('Mehr, wenn du magst'), findsNothing);
    });
  });

  group('Ohne Ort', () {
    testWidgets('sagt der Bildschirm, was fehlt', (WidgetTester tester) async {
      await oeffne(tester, ort: null);
      expect(find.text('Noch kein Ort eingestellt'), findsOneWidget);
      expect(find.text('Ort einstellen'), findsOneWidget);
    });

    testWidgets('die Azkar lassen sich trotzdem sprechen',
        (WidgetTester tester) async {
      // Ohne Zeiten fehlt die Erinnerung — der Text ist davon unberührt.
      await oeffne(tester, ort: null);
      expect(find.textContaining('Quran 2:255'), findsOneWidget);
    });
  });

  group('Layout', () {
    testWidgets('320 px und 150 % Schrift laufen nicht über',
        (WidgetTester tester) async {
      await oeffne(tester,
          groesse: const Size(320, 9000), scale: 1.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('jede Karte hat einen Vorlese-Knopf',
        (WidgetTester tester) async {
      await oeffne(tester);
      expect(find.byType(SpeakButton), findsWidgets);
    });
  });
}
