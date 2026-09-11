import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/content_registry.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/custom_cards.dart';
import 'package:ipa_testing_github_action/state/daily_card_store.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';

VocabEntry _karte(int i) => VocabEntry.fact(
      'Begriff $i',
      'Bedeutung $i',
      explanation: 'Erklärung $i',
      source: 'Wikipedia',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Der Speicher', () {
    test('nimmt die Karten eines Tages auf', () async {
      final DailyCardStore store = DailyCardStore();
      await store.load();
      expect(store.isEmpty, isTrue);

      final List<String> weg =
          await store.addAll(<VocabEntry>[_karte(1), _karte(2)]);
      expect(weg, isEmpty);
      expect(store.length, 2);
      expect(store.latest, hasLength(2), reason: 'neu von heute');
    });

    test('derselbe Fund zweimal ergibt eine Karte', () async {
      final DailyCardStore store = DailyCardStore();
      await store.addAll(<VocabEntry>[_karte(1)]);
      await store.addAll(<VocabEntry>[_karte(1), _karte(2)]);
      expect(store.length, 2);
      expect(store.latest, hasLength(1), reason: 'nur die wirklich neue');
    });

    test('neueste zuerst', () async {
      final DailyCardStore store = DailyCardStore();
      await store.addAll(<VocabEntry>[_karte(1)]);
      await store.addAll(<VocabEntry>[_karte(2)]);
      expect(store.cards.first.german, 'Begriff 2');
    });

    test('innerhalb eines Tages bleibt die Reihenfolge der Quelle', () async {
      // Artikel des Tages zuerst, dann das Ereignis — so kommen sie an, und
      // so sollen sie auch dastehen.
      final DailyCardStore store = DailyCardStore();
      await store.addAll(<VocabEntry>[_karte(1), _karte(2)]);
      expect(store.cards.map((VocabEntry c) => c.german),
          <String>['Begriff 1', 'Begriff 2']);
    });

    test('übersteht einen Neustart', () async {
      final DailyCardStore erst = DailyCardStore();
      await erst.addAll(<VocabEntry>[_karte(1), _karte(2)]);

      final DailyCardStore wieder = DailyCardStore();
      await wieder.load();
      expect(wieder.length, 2);
      expect(wieder.cards.first.german, 'Begriff 1');
      expect(wieder.cards.first.explanation, 'Erklärung 1');
      expect(wieder.cards.first.source, 'Wikipedia');
    });
  });

  group('Die Grenze', () {
    test('über 180 fallen die ältesten weg und werden genannt', () async {
      // Tag für Tag, nicht alles auf einmal: Erst dann gibt es überhaupt
      // ein „älter" und ein „neuer".
      final DailyCardStore store = DailyCardStore();
      for (int tag = 0; tag < DailyCardStore.maxCards; tag++) {
        await store.addAll(<VocabEntry>[_karte(tag)]);
      }
      expect(store.length, DailyCardStore.maxCards);

      final List<String> weg = await store.addAll(<VocabEntry>[
        _karte(1000),
        _karte(1001),
      ]);
      expect(store.length, DailyCardStore.maxCards);
      expect(weg, hasLength(2));
      // Die ältesten: die zuerst abgelegten.
      expect(weg, contains(_karte(0).id));
      expect(weg, contains(_karte(1).id));
      expect(store.contains(_karte(0).id), isFalse);
      expect(store.contains(_karte(1000).id), isTrue);
    });

    test('der Lernstand vergisst genau die weggefallenen', () async {
      final LearningState state = LearningState(store: ProgressStore());
      await state.load();

      final VocabEntry bleibt = _karte(1);
      final VocabEntry faellt = _karte(2);
      state.promote(bleibt);
      state.promote(faellt);
      expect(state.progressOfWord(bleibt).box, 1);
      expect(state.progressOfWord(faellt).box, 1);

      await state.forget(<String>[faellt.id]);
      expect(state.progressOfWord(bleibt).box, 1, reason: 'unberührt');
      expect(state.progressOfWord(faellt).box, 0, reason: 'vergessen');
    });

    test('vergessen, was nie da war, ändert nichts', () async {
      final LearningState state = LearningState(store: ProgressStore());
      await state.load();
      await state.forget(<String>['gibt|es|nicht']);
      expect(state.answered, 0);
    });
  });

  group('Der Schalter', () {
    test('aus heißt: es kommt nichts dazu', () async {
      final DailyCardStore store = DailyCardStore();
      await store.load();
      await store.setEnabled(false);

      final List<String> weg = await store.addAll(<VocabEntry>[_karte(1)]);
      expect(weg, isEmpty);
      expect(store.isEmpty, isTrue);
    });

    test('aus lässt liegen, was schon da ist', () async {
      final DailyCardStore store = DailyCardStore();
      await store.addAll(<VocabEntry>[_karte(1)]);
      await store.setEnabled(false);
      expect(store.length, 1, reason: 'nichts gelöscht, nur nichts Neues');
    });

    test('der Schalter übersteht einen Neustart', () async {
      final DailyCardStore erst = DailyCardStore();
      await erst.load();
      await erst.setEnabled(false);

      final DailyCardStore wieder = DailyCardStore();
      await wieder.load();
      expect(wieder.enabled, isFalse);
    });

    test('standardmäßig an', () async {
      final DailyCardStore store = DailyCardStore();
      await store.load();
      expect(store.enabled, isTrue);
    });
  });

  group('Zwei Speicher, zwei Themen', () {
    test('Tagesfunde und Meine Karten bleiben getrennt', () async {
      final CustomCardStore gemerkt = CustomCardStore();
      final DailyCardStore funde = DailyCardStore();
      await gemerkt.add(_karte(1));
      await funde.addAll(<VocabEntry>[_karte(2)]);

      final ContentWithCustomCards inhalt =
          ContentWithCustomCards(kDefaultContent, gemerkt, funde);
      final CategoryGroup gruppe = inhalt.groups.last;
      expect(gruppe.id, ContentWithCustomCards.customGroupId);
      expect(gruppe.categories.map((VocabCategory c) => c.id), <String>[
        ContentWithCustomCards.customCategoryId,
        ContentWithCustomCards.dailyCategoryId,
      ]);

      // Und der Lernkern sieht beide.
      expect(inhalt.entries.map((VocabEntry e) => e.id),
          containsAll(<String>[_karte(1).id, _karte(2).id]));
    });

    test('ein Speicher zu leeren rührt den anderen nicht an', () async {
      // Das ist der Grund für zwei Speicher: „Alles löschen" auf den
      // gemerkten Karten darf die Tagesfunde nicht mitnehmen.
      final CustomCardStore gemerkt = CustomCardStore();
      final DailyCardStore funde = DailyCardStore();
      await gemerkt.add(_karte(1));
      await funde.addAll(<VocabEntry>[_karte(2)]);

      await gemerkt.clear();
      expect(gemerkt.isEmpty, isTrue);
      expect(funde.length, 1);

      await funde.clear();
      expect(funde.isEmpty, isTrue);
    });

    test('ohne Tagesfunde verhält sich alles wie vorher', () async {
      final CustomCardStore gemerkt = CustomCardStore();
      await gemerkt.add(_karte(1));
      final ContentWithCustomCards inhalt =
          ContentWithCustomCards(kDefaultContent, gemerkt);
      expect(inhalt.groups.last.categories, hasLength(1));
    });

    test('ganz ohne Karten gibt es den Bereich nicht', () async {
      final ContentWithCustomCards inhalt = ContentWithCustomCards(
          kDefaultContent, CustomCardStore(), DailyCardStore());
      expect(inhalt.groups.length, kDefaultContent.groups.length);
    });
  });

  group('Kaputter Speicher', () {
    test('kostet die Funde, nicht die App', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyCardStore.storageKey: '{kein json',
      });
      final DailyCardStore store = DailyCardStore();
      await store.load();
      expect(store.isEmpty, isTrue);
      expect(store.enabled, isTrue);
    });

    test('ein unbrauchbarer Eintrag kostet diese eine Karte', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyCardStore.storageKey: '{"enabled":true,"cards":['
            '{"term":"Gut","answer":"Brauchbar"},'
            '{"term":"","answer":"leer"},'
            '"kein Objekt"]}',
      });
      final DailyCardStore store = DailyCardStore();
      await store.load();
      expect(store.length, 1);
      expect(store.cards.single.german, 'Gut');
    });
  });
}
