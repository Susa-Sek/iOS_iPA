import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/state/backup.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/word_progress.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';

/// Eine Sicherung ohne Dateisystem: merkt sich, was geschrieben worden wäre,
/// und gibt zurück, was der Test hineinlegt.
class FakeBackupBackend implements BackupBackend {
  FakeBackupBackend({this.zumLesen, this.kannSchreiben = true});

  String? zumLesen;
  final bool kannSchreiben;
  String? geschriebenerName;
  String? geschriebenerInhalt;

  @override
  Future<bool> write(String dateiname, String inhalt) async {
    if (!kannSchreiben) return false;
    geschriebenerName = dateiname;
    geschriebenerInhalt = inhalt;
    return true;
  }

  @override
  Future<String?> read() async => zumLesen;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  StoredProgress beispiel() => StoredProgress(
        words: <String, WordProgress>{
          'Haus|بيت': WordProgress(
            box: 3,
            due: DateTime(2026, 10, 11),
            lastAnswered: DateTime(2026, 10, 4),
          ),
          'Tee|شاي': WordProgress(box: 5, due: DateTime(2026, 12, 3)),
        },
        answered: 412,
        correct: 377,
        bestStreak: 29,
        dailyGoal: 12,
        history: const <String, int>{'2026-10-03': 14, '2026-10-04': 9},
        xp: 1840,
        perfectRounds: 7,
        goalDays: 41,
        freezes: 2,
        frozenDays: const <String>{'2026-09-18'},
        shortsDone: 220,
        questDays: 31,
        freezesEarned: 5,
        sessionKinds: const <String>['karteikarten', 'quiz'],
        sessionBlocks: 4,
        blockSize: 15,
      );

  group('Sichern und zurückholen', () {
    test('was herauskommt, kommt auch wieder hinein', () {
      final StoredProgress vorher = beispiel();
      final StoredProgress? nachher =
          readBackup(makeBackup(vorher, DateTime(2026, 10, 4)));

      expect(nachher, isNotNull);
      expect(nachher!.answered, vorher.answered);
      expect(nachher.correct, vorher.correct);
      expect(nachher.bestStreak, vorher.bestStreak);
      expect(nachher.dailyGoal, vorher.dailyGoal);
      expect(nachher.xp, vorher.xp);
      expect(nachher.goalDays, vorher.goalDays);
      expect(nachher.freezes, vorher.freezes);
      expect(nachher.frozenDays, vorher.frozenDays);
      expect(nachher.history, vorher.history);
      expect(nachher.sessionKinds, vorher.sessionKinds);
      expect(nachher.sessionBlocks, vorher.sessionBlocks);
      expect(nachher.blockSize, vorher.blockSize);
    });

    test('die Fächer und Termine überleben', () {
      final StoredProgress? nachher =
          readBackup(makeBackup(beispiel(), DateTime(2026, 10, 4)));
      final WordProgress haus = nachher!.words['Haus|بيت']!;
      expect(haus.box, 3);
      expect(haus.due, DateTime(2026, 10, 11));
      expect(haus.lastAnswered, DateTime(2026, 10, 4));
      expect(nachher.words['Tee|شاي']!.box, 5);
    });

    test('der Dateiname trägt das Datum', () {
      expect(backupName(DateTime(2026, 10, 4)),
          'taeglich-klueger-2026-10-04.json');
    });

    test('die Datei ist lesbar und erkennbar', () {
      final Map<String, dynamic> json = jsonDecode(
          makeBackup(beispiel(), DateTime(2026, 10, 4))) as Map<String, dynamic>;
      expect(json['app'], kBackupMarker);
      expect(json['format'], kBackupFormat);
      expect(json['saved'], startsWith('2026-10-04'));
      expect(json['progress'], isA<Map<String, dynamic>>());
    });
  });

  group('Was keine Sicherung ist, ändert nichts', () {
    test('kaputtes JSON', () {
      expect(readBackup('{kein json'), isNull);
      expect(readBackup(''), isNull);
      expect(readBackup('[]'), isNull);
    });

    test('eine fremde JSON-Datei', () {
      // Ohne Kennzeichen kein Einspielen — sonst ginge irgendeine Datei aus
      // dem Download-Ordner als Lernstand durch.
      expect(readBackup('{"answered": 5}'), isNull);
      expect(readBackup('{"app":"etwas anderes","progress":{}}'), isNull);
    });

    test('eine Sicherung ohne Inhalt', () {
      expect(readBackup('{"app":"$kBackupMarker","format":1}'), isNull);
    });

    test('eine Sicherung aus einer älteren Version liest sich', () {
      // Nur die Felder von damals — alles Neue nimmt seine Vorgabe.
      final StoredProgress? alt = readBackup(jsonEncode(<String, dynamic>{
        'app': kBackupMarker,
        'format': 1,
        'progress': <String, dynamic>{
          'answered': 100,
          'correct': 90,
          'dailyGoal': 10,
          'words': <String, dynamic>{
            'Haus|بيت': <String, dynamic>{'b': 2},
          },
        },
      }));
      expect(alt, isNotNull);
      expect(alt!.answered, 100);
      expect(alt.words['Haus|بيت']!.box, 2);
      expect(alt.blockSize, 0, reason: 'Vorgabe, nicht erfunden');
      expect(alt.sessionKinds, isEmpty);
    });
  });

  group('Der Dienst', () {
    test('sichern gibt Name und Inhalt heraus', () async {
      final FakeBackupBackend backend = FakeBackupBackend();
      final BackupService service = BackupService(
          backend: backend, clock: () => DateTime(2026, 10, 4));

      expect(await service.sichern(beispiel()), isTrue);
      expect(backend.geschriebenerName, 'taeglich-klueger-2026-10-04.json');
      expect(readBackup(backend.geschriebenerInhalt!)!.answered, 412);
    });

    test('ohne Ziel zum Ablegen meldet es sich', () async {
      final BackupService service =
          BackupService(backend: FakeBackupBackend(kannSchreiben: false));
      expect(await service.sichern(beispiel()), isFalse);
    });

    test('abgebrochene Auswahl ändert nichts', () async {
      final BackupService service = BackupService(backend: FakeBackupBackend());
      final (RestoreOutcome ausgang, StoredProgress? stand) =
          await service.lesen();
      expect(ausgang, RestoreOutcome.abgebrochen);
      expect(stand, isNull);
    });

    test('eine fremde Datei wird benannt, nicht eingespielt', () async {
      final BackupService service = BackupService(
          backend: FakeBackupBackend(zumLesen: '{"irgendwas": true}'));
      final (RestoreOutcome ausgang, StoredProgress? stand) =
          await service.lesen();
      expect(ausgang, RestoreOutcome.keineSicherung);
      expect(stand, isNull);
    });
  });

  group('Im Lernkern', () {
    test('restore ersetzt den ganzen Stand und überlebt den Neustart',
        () async {
      final LearningState state = LearningState(store: ProgressStore());
      await state.load();
      final VocabEntry wort = state.activeEntries.first;
      state.promote(wort);
      expect(state.answered, 0);

      final StoredProgress? sicherung =
          readBackup(makeBackup(beispiel(), DateTime(2026, 10, 4)));
      await state.restore(sicherung!);

      expect(state.answered, 412);
      expect(state.dailyGoal, 12);
      expect(state.blockSize, 15);
      expect(state.freezes, 2);
      expect(state.boxOf(wort), 0, reason: 'der alte Stand ist ersetzt');

      // Neue Instanz, wie nach einem Neustart.
      final LearningState wieder = LearningState(store: ProgressStore());
      await wieder.load();
      expect(wieder.answered, 412);
      expect(wieder.blockSize, 15);
    });

    test('snapshot und Sicherung tragen dasselbe', () async {
      final LearningState state = LearningState(store: ProgressStore());
      await state.load();
      await state.setDailyGoal(14);
      state.promote(state.activeEntries.first);

      final StoredProgress? zurueck =
          readBackup(makeBackup(state.snapshot, DateTime(2026, 10, 4)));
      expect(zurueck!.dailyGoal, 14);
      expect(zurueck.answered, state.answered);
      expect(zurueck.words.length, state.snapshot.words.length);
    });
  });
}
