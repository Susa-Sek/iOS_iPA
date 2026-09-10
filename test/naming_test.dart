import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/state/custom_cards.dart';
import 'package:ipa_testing_github_action/state/daily_feed.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/lesson_store.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/reminders.dart';
import 'package:ipa_testing_github_action/state/speech.dart';

/// Die Speicher-Schlüssel sind der Lernstand bestehender Nutzer.
///
/// Beim Umbau zu einer allgemeinen Lern-App liegt es nahe, überall
/// "arabisch_lernen" durch den neuen Namen zu ersetzen. Genau das darf nicht
/// passieren: Ein geänderter Schlüssel heißt, dass die App den gespeicherten
/// Fortschritt nicht mehr findet — Stufen, Termine, Punkte und Serie wären
/// beim nächsten Update weg, ohne Fehlermeldung.
///
/// Dieser Test friert die Schlüssel ein. Schlägt er an, ist das kein
/// Testproblem, sondern ein verhinderter Datenverlust.
void main() {
  group('Speicher-Schlüssel bleiben unverändert', () {
    test('Lernstand', () {
      expect(ProgressStore.storageKey, 'arabisch_lernen.progress.v1');
    });

    test('Sprechtempo', () {
      expect(Speaker.slowKey, 'arabisch_lernen.speech.slow');
    });

    test('Erinnerung', () {
      expect(ReminderService.enabledKey, 'arabisch_lernen.reminder.enabled');
      expect(ReminderService.hourKey, 'arabisch_lernen.reminder.hour');
      expect(ReminderService.minuteKey, 'arabisch_lernen.reminder.minute');
    });

    test('Tagesinhalte', () {
      expect(DailyFeedService.cacheKey, 'arabisch_lernen.feed.v1');
    });

    test('Lektionen', () {
      // Dieser Schlüssel hält, welche Lektionen durchgearbeitet sind — das
      // Maß des Fortschritts im Wissen.
      expect(LessonStore.storageKey, 'arabisch_lernen.lessons.v1');
    });

    test('gewähltes Fach', () {
      expect(LearningState.subjectKey, 'arabisch_lernen.subject');
    });

    test('gemerkte Karten', () {
      // Dieser Schlüssel hält die selbst gemerkten Karten. Geht er verloren,
      // sind sie weg — sie stehen nirgends sonst.
      expect(CustomCardStore.storageKey, 'arabisch_lernen.cards.v1');
    });
  });

  group('Paketname bleibt', () {
    test('Android-Anwendungs-id', () {
      // Steht in android/app/build.gradle.kts. Ein anderer Paketname heißt:
      // Die App gilt als andere App, kein Update, kein Lernstand.
      final String gradle =
          File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('de.susasek.arabischlernen'));
    });

    test('Dart-Paketname', () {
      // Er steckt in jedem Import der Tests; ein anderer Name wäre eine
      // Umbenennung quer durch das ganze Projekt ohne jeden Gewinn.
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('name: ipa_testing_github_action'));
    });
  });

  group('Anzeigename ist der neue', () {
    test('Android nimmt ihn aus strings.xml', () {
      // Direkt im Manifest wäre er nicht lokalisierbar und je nach
      // Werkzeugkette anfällig für die Umlaute.
      final String manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:label="@string/app_name"'));

      final String strings =
          File('android/app/src/main/res/values/strings.xml').readAsStringSync();
      expect(strings, contains('Täglich Klüger'));
    });

    test('iOS und Web tragen denselben Namen', () {
      expect(File('ios/Runner/Info.plist').readAsStringSync(),
          contains('Täglich Klüger'));
      expect(File('web/index.html').readAsStringSync(),
          contains('Täglich Klüger'));
      expect(File('web/manifest.json').readAsStringSync(),
          contains('Täglich Klüger'));
    });
  });
}
