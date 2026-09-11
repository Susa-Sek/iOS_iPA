import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/word_progress.dart';

/// Ein Lernstand mit einer Vorgeschichte, ohne dass Tage vergehen müssen.
///
/// Geschrieben wird direkt in den Speicher: `history` ist die Zahl der
/// Antworten je Tag, und das Tagesziel steht bei 10.
Future<LearningState> mitVergangenheit({
  required DateTime heute,
  required List<DateTime> aktiveTage,
  int freezes = 0,
  Set<String> frozenDays = const <String>{},
}) async {
  final ProgressStore store = ProgressStore();
  await store.save(StoredProgress(
    dailyGoal: 10,
    freezes: freezes,
    frozenDays: frozenDays,
    history: <String, int>{for (final DateTime d in aktiveTage) dayKey(d): 10},
  ));
  final LearningState state =
      LearningState(store: store, clock: () => heute);
  await state.load();
  return state;
}

List<DateTime> tageVor(DateTime heute, List<int> abstaende) => <DateTime>[
      for (final int n in abstaende) heute.subtract(Duration(days: n)),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final DateTime heute = DateTime(2026, 5, 20, 14);

  group('Ohne Jokertag bleibt alles wie bisher', () {
    test('eine ununterbrochene Serie zählt', () async {
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: tageVor(heute, <int>[1, 2, 3, 4]),
      );
      expect(state.dayStreak, 4);
      expect(state.freezes, 0);
    });

    test('ein verpasster Tag bricht sie', () async {
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: tageVor(heute, <int>[2, 3, 4, 5]),
      );
      expect(state.dayStreak, 0);
    });
  });

  group('Der Jokertag hält die Serie', () {
    test('ein verpasster Tag wird überbrückt', () async {
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: tageVor(heute, <int>[2, 3, 4, 5]),
        freezes: 1,
      );
      // Vier Tage Serie plus der gerettete — und der Joker ist verbraucht.
      expect(state.dayStreak, 5);
      expect(state.freezes, 0);
      expect(state.streakWasSaved, isTrue);
    });

    test('drei verpasste Tage mit drei Jokern auch', () async {
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: tageVor(heute, <int>[4, 5, 6]),
        freezes: 3,
      );
      expect(state.dayStreak, 6);
      expect(state.freezes, 0);
    });

    test('vier verpasste Tage nicht — auch nicht mit Vorrat', () async {
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: tageVor(heute, <int>[5, 6, 7]),
        freezes: 3,
      );
      // Lieber die Serie verlieren als drei Joker in eine Lücke werfen,
      // die sie ohnehin nicht schließen.
      expect(state.dayStreak, 0);
      expect(state.freezes, 3, reason: 'nichts verbraucht');
    });

    test('zu wenige Joker für die Lücke: keiner wird verbraucht', () async {
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: tageVor(heute, <int>[3, 4, 5]),
        freezes: 1,
      );
      expect(state.dayStreak, 0);
      expect(state.freezes, 1);
    });

    test('wer nach Monaten zurückkommt, verbraucht keinen', () async {
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: tageVor(heute, <int>[90, 91, 92]),
        freezes: 3,
      );
      expect(state.freezes, 3);
      expect(state.dayStreak, 0);
    });

    test('ohne Serie davor gibt es nichts zu halten', () async {
      // Gestern verpasst, davor auch nie etwas: Ein Joker würde eine Serie
      // erfinden, die es nie gab.
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: const <DateTime>[],
        freezes: 3,
      );
      expect(state.freezes, 3);
      expect(state.dayStreak, 0);
    });

    test('heute gelernt zählt zur geretteten Serie dazu', () async {
      final LearningState state = await mitVergangenheit(
        heute: heute,
        aktiveTage: tageVor(heute, <int>[2, 3]),
        freezes: 1,
      );
      for (int i = 0; i < 10; i++) {
        state.recordAnswer(correct: true);
      }
      expect(state.goalReached, isTrue);
      expect(state.dayStreak, 4, reason: 'heute + gerettet + zwei davor');
    });

    test('die Rettung übersteht einen Neustart', () async {
      final ProgressStore store = ProgressStore();
      await store.save(StoredProgress(
        dailyGoal: 10,
        freezes: 1,
        history: <String, int>{
          for (final DateTime d in tageVor(heute, <int>[2, 3]))
            dayKey(d): 10,
        },
      ));
      final LearningState erst =
          LearningState(store: store, clock: () => heute);
      await erst.load();
      expect(erst.dayStreak, 3);
      // Erst ein Schreibvorgang legt die Rettung ab.
      erst.recordAnswer(correct: true);
      await Future<void>.delayed(Duration.zero);

      final LearningState wieder =
          LearningState(store: ProgressStore(), clock: () => heute);
      await wieder.load();
      expect(wieder.dayStreak, 3);
      expect(wieder.freezes, 0);
    });
  });

  group('Jokertage verdienen', () {
    test('einer kommt dazu, höchstens drei liegen bereit', () async {
      final LearningState state =
          await mitVergangenheit(heute: heute, aktiveTage: const <DateTime>[]);
      expect(await state.earnFreeze(), isTrue);
      expect(await state.earnFreeze(), isTrue);
      expect(await state.earnFreeze(), isTrue);
      expect(state.freezes, LearningState.maxFreezes);
      // Der vierte verfällt — und sagt das, damit nichts gemeldet wird,
      // was nicht passiert ist.
      expect(await state.earnFreeze(), isFalse);
      expect(state.freezes, LearningState.maxFreezes);
    });
  });

  group('Alte Installationen', () {
    test('ein Stand ohne die neuen Felder wird unverändert gelesen', () async {
      // Genau der Stand, den eine App vor dem Jokertag geschrieben hat.
      const String alt = '{"answered":42,"correct":30,"bestStreak":7,'
          '"dailyGoal":10,"xp":500,"perfectRounds":2,"goalDays":3,'
          '"history":{"2026-05-19":12},"words":{}}';
      final StoredProgress stand = ProgressStore.decode(alt);
      expect(stand.answered, 42);
      expect(stand.xp, 500);
      expect(stand.bestStreak, 7);
      expect(stand.freezes, 0);
      expect(stand.frozenDays, isEmpty);
    });
  });
}
