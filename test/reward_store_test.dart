import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/state/daily_quests.dart';
import 'package:ipa_testing_github_action/state/reward_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  List<Quest> heutigeAufgaben(DateTime tag) => buildQuests(
        day: tag,
        dailyGoal: 10,
        hatArabisch: true,
        hatWissen: true,
      );

  group('Tagesaufgaben zählen mit', () {
    test('was gemeldet wird, steht drin', () async {
      final RewardStore store = RewardStore(clock: () => DateTime(2026, 5, 20));
      await store.load();
      expect(store.progressOf(QuestKind.antworten), 0);

      await store.report(QuestKind.antworten);
      await store.report(QuestKind.antworten, amount: 4);
      expect(store.progressOf(QuestKind.antworten), 5);
      expect(store.progressOf(QuestKind.richtige), 0);
    });

    test('der Stand übersteht einen Neustart', () async {
      DateTime jetzt = DateTime(2026, 5, 20, 10);
      final RewardStore erst = RewardStore(clock: () => jetzt);
      await erst.load();
      await erst.report(QuestKind.lektion);

      final RewardStore wieder = RewardStore(clock: () => jetzt);
      await wieder.load();
      expect(wieder.progressOf(QuestKind.lektion), 1);
    });

    test('ein neuer Tag fängt bei null an', () async {
      DateTime jetzt = DateTime(2026, 5, 20, 22);
      final RewardStore store = RewardStore(clock: () => jetzt);
      await store.load();
      await store.report(QuestKind.antworten, amount: 12);
      await store.markFreezeEarned();
      expect(store.progressOf(QuestKind.antworten), 12);
      expect(store.freezeEarnedToday, isTrue);

      jetzt = DateTime(2026, 5, 21, 7);
      final RewardStore morgen = RewardStore(clock: () => jetzt);
      await morgen.load();
      expect(morgen.progressOf(QuestKind.antworten), 0);
      expect(morgen.freezeEarnedToday, isFalse);
    });

    test('erledigt zählt, wenn jede Aufgabe ihr Ziel hat', () async {
      final DateTime tag = DateTime(2026, 5, 20);
      final RewardStore store = RewardStore(clock: () => tag);
      await store.load();
      final List<Quest> aufgaben = heutigeAufgaben(tag);

      expect(store.allDone(aufgaben), isFalse);
      expect(store.doneCount(aufgaben), 0);

      for (final Quest q in aufgaben) {
        await store.report(q.kind, amount: q.target);
      }
      expect(store.doneCount(aufgaben), 3);
      expect(store.allDone(aufgaben), isTrue);
    });

    test('der Jokertag wird nur einmal am Tag vergeben', () async {
      final RewardStore store = RewardStore(clock: () => DateTime(2026, 5, 20));
      await store.load();
      await store.markFreezeEarned();
      await store.markFreezeEarned();
      expect(store.freezeEarnedToday, isTrue);
    });
  });

  group('Gemeldete Abzeichen', () {
    test('ein Abzeichen gilt nach der Meldung als gesehen', () async {
      final RewardStore store = RewardStore();
      await store.load();
      expect(store.wasAnnounced('first_ten'), isFalse);

      await store.markAnnounced(<String>['first_ten', 'streak_3']);
      expect(store.wasAnnounced('first_ten'), isTrue);
      expect(store.wasAnnounced('streak_3'), isTrue);
      expect(store.wasAnnounced('words_50'), isFalse);
    });

    test('gesehen bleibt gesehen — auch am nächsten Tag', () async {
      DateTime jetzt = DateTime(2026, 5, 20);
      final RewardStore store = RewardStore(clock: () => jetzt);
      await store.load();
      await store.markAnnounced(<String>['first_ten']);

      jetzt = DateTime(2026, 6, 30);
      final RewardStore spaeter = RewardStore(clock: () => jetzt);
      await spaeter.load();
      expect(spaeter.wasAnnounced('first_ten'), isTrue);
      expect(spaeter.progressOf(QuestKind.antworten), 0);
    });

    test('ein frischer Speicher sagt, dass er frisch ist', () async {
      // Darauf beruht, dass beim ersten Start nach dem Update nicht zwölf
      // alte Abzeichen hintereinander hochgehen.
      final RewardStore frisch = RewardStore();
      await frisch.load();
      expect(frisch.isFresh, isTrue);

      await frisch.markAnnounced(<String>['first_ten']);
      final RewardStore wieder = RewardStore();
      await wieder.load();
      expect(wieder.isFresh, isFalse);
    });
  });

  group('Kaputter Speicher', () {
    test('kostet den Tagesstand, nicht die App', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        RewardStore.storageKey: '{kein json',
      });
      final RewardStore store = RewardStore();
      await store.load();
      expect(store.progressOf(QuestKind.antworten), 0);
      expect(store.wasAnnounced('first_ten'), isFalse);
    });

    test('unbekannte Aufgabenarten werden übersprungen', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        RewardStore.storageKey: '{"day":"2026-05-20",'
            '"quests":{"antworten":3,"gibtsNichtMehr":9},"seen":["a"]}',
      });
      final RewardStore store = RewardStore(clock: () => DateTime(2026, 5, 20));
      await store.load();
      expect(store.progressOf(QuestKind.antworten), 3);
      expect(store.wasAnnounced('a'), isTrue);
    });
  });
}
