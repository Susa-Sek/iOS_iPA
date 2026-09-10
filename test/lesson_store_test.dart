import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/knowledge/lessons.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/lesson_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final VocabCategory thema = kKnowledgeCategories.first;
  final List<KnowledgeLesson> lektionen = lessonsOf(thema);

  Future<LessonStore> geladen({DateTime? jetzt}) async {
    final LessonStore store =
        LessonStore(clock: jetzt == null ? null : () => jetzt);
    await store.load();
    return store;
  }

  group('Fortschritt', () {
    test('am Anfang ist nichts erledigt', () async {
      final LessonStore store = await geladen();
      expect(store.doneCount, 0);
      expect(store.isDone(lektionen.first.id), isFalse);
      expect(store.progressIn(thema), 0);
      expect(store.isUnderstood(thema), isFalse);
    });

    test('erledigt wird gespeichert und wiedergefunden', () async {
      final LessonStore store = await geladen();
      await store.markDone(lektionen.first.id);

      final LessonStore neu = await geladen();
      expect(neu.isDone(lektionen.first.id), isTrue);
      expect(neu.doneAt(lektionen.first.id), isNotNull);
      expect(neu.doneCount, 1);
    });

    test('ein Thema gilt erst mit allen Lektionen als verstanden', () async {
      final LessonStore store = await geladen();
      await store.markDone(lektionen.first.id);
      expect(store.doneIn(thema), 1);
      expect(store.progressIn(thema), 0.5);
      expect(store.isUnderstood(thema), isFalse);

      await store.markDone(lektionen.last.id);
      expect(store.isUnderstood(thema), isTrue);
      expect(store.progressIn(thema), 1.0);
      expect(store.understoodIn(kKnowledgeCategories), 1);
    });

    test('zweimal dieselbe Lektion zählt einmal', () async {
      final LessonStore store = await geladen();
      await store.markDone(lektionen.first.id);
      await store.markDone(lektionen.first.id);
      expect(store.doneCount, 1);
    });

    test('meldet jede Änderung', () async {
      final LessonStore store = await geladen();
      int meldungen = 0;
      store.addListener(() => meldungen++);
      await store.markDone(lektionen.first.id);
      expect(meldungen, greaterThanOrEqualTo(1));
    });

    test('zurücksetzen leert alles', () async {
      final LessonStore store = await geladen();
      await store.markDone(lektionen.first.id);
      await store.reset();
      expect(store.doneCount, 0);
      expect((await geladen()).doneCount, 0);
    });
  });

  group('Die nächste Lektion', () {
    test('ist am Anfang die erste', () async {
      final LessonStore store = await geladen();
      expect(store.nextLesson()!.id, kLessons.first.id);
    });

    test('rückt weiter, sobald eine erledigt ist', () async {
      final LessonStore store = await geladen();
      await store.markDone(kLessons.first.id);
      expect(store.nextLesson()!.id, kLessons[1].id);
    });

    test('ist alles durch, kommt die am längsten zurückliegende', () async {
      // Eine abgeschlossene App darf keine Sackgasse sein.
      final LessonStore store = await geladen(jetzt: DateTime(2026, 1, 1));
      for (final KnowledgeLesson lesson in kLessons) {
        await store.markDone(lesson.id);
      }
      final LessonStore spaeter = LessonStore(clock: () => DateTime(2026, 2, 1));
      await spaeter.load();
      await spaeter.markDone(kLessons.last.id);

      final LessonStore jetzt = await geladen();
      expect(jetzt.nextLesson(), isNotNull);
      expect(jetzt.nextLesson()!.id, isNot(kLessons.last.id));
    });

    test('ein leerer Vorrat ergibt nichts', () async {
      final LessonStore store = await geladen();
      expect(store.nextLesson(const <KnowledgeLesson>[]), isNull);
    });
  });

  group('Kaputter Speicher', () {
    test('kostet nur die kaputten Einträge', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LessonStore.storageKey:
            '{"w_geografie.1":"2026-05-01T10:00:00.000","kaputt":"gestern",'
            '"w_geografie.2":42}',
      });
      final LessonStore store = await geladen();
      expect(store.doneCount, 1);
      expect(store.isDone('w_geografie.1'), isTrue);
      expect(store.isDone('w_geografie.2'), isFalse);
    });

    test('unlesbarer Speicher endet leer statt in einem Fehler', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LessonStore.storageKey: 'das ist kein JSON',
      });
      expect((await geladen()).doneCount, 0);
    });
  });
}
