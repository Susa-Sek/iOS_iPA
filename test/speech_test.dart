import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/state/speech.dart';
import 'package:ipa_testing_github_action/widgets/speak_button.dart';

/// Stands in for the platform engine, so the speaking logic can be tested.
class FakeBackend implements SpeechBackend {
  FakeBackend({this.hasVoice = true});

  final bool hasVoice;
  final List<String> spoken = <String>[];
  final List<String> languages = <String>[];
  final List<double> rates = <double>[];
  int stops = 0;
  String? preparedLanguage;

  @override
  Future<bool> prepare(String language) async {
    preparedLanguage = language;
    return hasVoice;
  }

  @override
  Future<void> setLanguage(String language) async => languages.add(language);

  @override
  Future<void> setRate(double rate) async => rates.add(rate);

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Speaker', () {
    test('meldet sich bereit, wenn eine arabische Stimme da ist', () async {
      final FakeBackend backend = FakeBackend();
      final Speaker speaker = Speaker(backend: backend);
      await speaker.init();

      expect(backend.preparedLanguage, 'ar');
      expect(speaker.status, SpeechStatus.ready);
      expect(speaker.isAvailable, isTrue);
    });

    test('ohne arabische Stimme bleibt es still statt zu stürzen', () async {
      final FakeBackend backend = FakeBackend(hasVoice: false);
      final Speaker speaker = Speaker(backend: backend);
      await speaker.init();

      expect(speaker.status, SpeechStatus.unavailable);
      await speaker.speak('كِتَاب');
      expect(backend.spoken, isEmpty);
    });

    test('spricht das vokalisierte Wort', () async {
      final FakeBackend backend = FakeBackend();
      final Speaker speaker = Speaker(backend: backend);
      await speaker.init();
      await speaker.speak('شُكْرًا');
      expect(backend.spoken, <String>['شُكْرًا']);
    });

    test('leerer Text wird nicht gesprochen', () async {
      final FakeBackend backend = FakeBackend();
      final Speaker speaker = Speaker(backend: backend);
      await speaker.init();
      await speaker.speak('   ');
      expect(backend.spoken, isEmpty);
    });

    test('startet langsam und merkt sich das Tempo', () async {
      final FakeBackend backend = FakeBackend();
      final Speaker speaker = Speaker(backend: backend);
      await speaker.init();
      expect(speaker.slow, isTrue);
      expect(backend.rates.last, Speaker.slowRate);

      await speaker.setSlow(false);
      expect(backend.rates.last, Speaker.normalRate);

      // Neue Instanz — die Einstellung ist gespeichert.
      final Speaker again = Speaker(backend: FakeBackend());
      await again.init();
      expect(again.slow, isFalse);
    });
  });

  group('SpeakButton', () {
    Widget wrap(Speaker speaker, Widget child) => SpeechScope(
          speaker: speaker,
          child: MaterialApp(home: Scaffold(body: Center(child: child))),
        );

    testWidgets('spricht das Wort beim Antippen', (WidgetTester tester) async {
      final FakeBackend backend = FakeBackend();
      final Speaker speaker = Speaker(backend: backend);
      await speaker.init();

      await tester.pumpWidget(wrap(speaker, const SpeakButton(text: 'قَمَر')));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(backend.spoken, <String>['قَمَر']);
    });

    testWidgets('erklärt, wenn keine Stimme installiert ist',
        (WidgetTester tester) async {
      final FakeBackend backend = FakeBackend(hasVoice: false);
      final Speaker speaker = Speaker(backend: backend);
      await speaker.init();

      await tester.pumpWidget(wrap(speaker, const SpeakButton(text: 'قَمَر')));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('Keine arabische Stimme'), findsOneWidget);
      expect(backend.spoken, isEmpty);
    });
  });
}
