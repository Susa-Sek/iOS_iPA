import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/content_registry.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/daily_item.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/custom_cards.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

const VocabEntry _karte = VocabEntry.fact(
  'Kragenhai',
  'Art der Gattung Kragenhaie',
  explanation: 'Ein altertümlicher Hai aus der Tiefsee.',
  source: 'Wikipedia · https://de.wikipedia.org/wiki/Kragenhai',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Gemerkte Karten', () {
    test('werden abgelegt und wiedergefunden', () async {
      final CustomCardStore store = CustomCardStore();
      await store.load();
      expect(await store.add(_karte), isTrue);

      final CustomCardStore neu = CustomCardStore();
      await neu.load();
      expect(neu.cards, hasLength(1));
      expect(neu.cards.single.german, 'Kragenhai');
      expect(neu.cards.single.explanation, isNotNull);
      expect(neu.cards.single.source, contains('Wikipedia'));
      expect(neu.cards.single.isLanguage, isFalse);
      expect(neu.contains(_karte.id), isTrue);
    });

    test('eine Frage behält ihre Ablenker', () async {
      const VocabEntry frage = VocabEntry.question(
        'In welchem Jahr: Etwas geschah.',
        '1996',
        distractors: <String>['1993', '2003', '1984'],
        explanation: 'Etwas geschah.',
      );
      final CustomCardStore store = CustomCardStore();
      await store.add(frage);

      final CustomCardStore neu = CustomCardStore();
      await neu.load();
      expect(neu.cards.single.distractors, <String>['1993', '2003', '1984']);
      expect(neu.cards.single.question, startsWith('In welchem Jahr:'));
    });

    test('dieselbe Karte kommt nur einmal hinein', () async {
      final CustomCardStore store = CustomCardStore();
      expect(await store.add(_karte), isTrue);
      expect(await store.add(_karte), isFalse);
      expect(store.cards, hasLength(1));
    });

    test('lassen sich wieder entfernen', () async {
      final CustomCardStore store = CustomCardStore();
      await store.add(_karte);
      await store.remove(_karte.id);
      expect(store.cards, isEmpty);

      final CustomCardStore neu = CustomCardStore();
      await neu.load();
      expect(neu.cards, isEmpty);
    });

    test('melden jede Änderung', () async {
      final CustomCardStore store = CustomCardStore();
      int meldungen = 0;
      store.addListener(() => meldungen++);
      await store.add(_karte);
      await store.remove(_karte.id);
      expect(meldungen, greaterThanOrEqualTo(2));
    });

    test('ein kaputter Speicher kostet nicht die ganze Sammlung', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        CustomCardStore.storageKey:
            '[{"term":"A","answer":"gut"},{"term":"B"},"kein Objekt"]',
      });
      final CustomCardStore store = CustomCardStore();
      await store.load();
      expect(store.cards, hasLength(1));
      expect(store.cards.single.german, 'A');
    });

    test('unlesbarer Speicher endet leer statt in einem Fehler', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        CustomCardStore.storageKey: 'das ist kein JSON',
      });
      final CustomCardStore store = CustomCardStore();
      await store.load();
      expect(store.cards, isEmpty);
    });
  });

  group('Registry mit gemerkten Karten', () {
    test('reicht den arabischen Bestand unverändert durch', () async {
      final CustomCardStore store = CustomCardStore();
      await store.load();
      final ContentWithCustomCards content =
          ContentWithCustomCards(kDefaultContent, store);

      expect(content.entries.length, kAllEntries.length);
      expect(content.categories.length, kAllCategories.length);
      expect(content.groups.length, kDefaultContent.groups.length);
      // Ohne gemerkte Karten gibt es das Thema gar nicht.
      expect(content.categoryById(ContentWithCustomCards.customCategoryId),
          isNull);
    });

    test('hängt die Karten als eigenes Thema an', () async {
      final CustomCardStore store = CustomCardStore();
      await store.add(_karte);
      final ContentWithCustomCards content =
          ContentWithCustomCards(kDefaultContent, store);

      expect(content.entries.length, kAllEntries.length + 1);
      expect(content.groups.length, kDefaultContent.groups.length + 1);

      final VocabCategory? thema =
          content.categoryById(ContentWithCustomCards.customCategoryId);
      expect(thema, isNotNull);
      expect(thema!.name, 'Meine Karten');
      expect(thema.isLanguage, isFalse);
      expect(thema.entries.single.german, 'Kragenhai');
    });

    test('der Lernkern zählt die neue Karte mit', () async {
      final CustomCardStore store = CustomCardStore();
      final LearningState state = LearningState(
        content: ContentWithCustomCards(kDefaultContent, store),
      );
      await state.load();
      final int vorher = state.totalCount;

      await store.add(_karte);
      expect(state.totalCount, vorher + 1);
    });

    test('eine Nachricht kommt dort nie an', () {
      const DailyItem meldung = DailyItem(
        kind: DailyItemKind.news,
        title: 'Irgendeine Meldung',
        text: 'Erster Satz.',
      );
      expect(meldung.toCard(), isNull);
    });
  });
}
