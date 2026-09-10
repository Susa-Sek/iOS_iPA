import 'package:flutter_test/flutter_test.dart';

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
  });
}
