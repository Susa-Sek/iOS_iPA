import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/models/daily_item.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/daily_feed.dart';
import 'package:ipa_testing_github_action/state/daily_harvest.dart';

import 'helpers.dart';

DailyItem _artikel(String titel) => DailyItem(
      kind: DailyItemKind.article,
      title: titel,
      text: 'Ein Auszug über $titel, lang genug für eine Erklärung.',
      subtitle: 'Kurzbeschreibung zu $titel',
      url: 'https://de.wikipedia.org/wiki/$titel',
    );

DailyItem _ereignis(int jahr, String was) => DailyItem(
      kind: DailyItemKind.event,
      title: '$jahr',
      text: was,
      year: jahr,
    );

DailyItem get _meldung => const DailyItem(
      kind: DailyItemKind.news,
      title: 'Eilmeldung',
      text: 'Irgendetwas ist gerade passiert.',
    );

/// Der Tag, für den geerntet wird — die Ernte hängt nicht daran, aber
/// `DailyFeed` verlangt ihn.
final DateTime _tag = DateTime(2026, 9, 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('Die Tagesernte', () {
    test('macht aus dem Artikel eine Begriffskarte', () {
      final List<VocabEntry> ernte =
          harvestDaily(DailyFeed(day: _tag, article: _artikel('Golfstrom')));

      expect(ernte, hasLength(1));
      expect(ernte.single.german, 'Golfstrom');
      expect(ernte.single.question, isNull, reason: 'kein Quiz, ein Begriff');
      expect(ernte.single.distractors, isEmpty);
      expect(ernte.single.explanation, isNotEmpty);
      // Die Quelle muss dranstehen, wo der Text steht.
      expect(ernte.single.source, contains('Wikipedia'));
    });

    test('macht aus einem Ereignis eine Jahresfrage', () {
      final List<VocabEntry> ernte = harvestDaily(
        DailyFeed(day: _tag, events: <DailyItem>[_ereignis(1969, 'Menschen auf dem Mond')]),
        currentYear: 2026,
      );

      expect(ernte, hasLength(1));
      expect(ernte.single.question, isNotNull);
      expect(ernte.single.answer, '1969');
      expect(ernte.single.distractors, hasLength(3));
      expect(ernte.single.distractors, isNot(contains('1969')));
    });

    test('die Jahres-Ablenker liegen dicht dabei und nie in der Zukunft', () {
      // Beim geschriebenen Bestand heißt die Hausregel „dasselbe
      // Jahrhundert" (knowledge_data_test.dart). Hier ist sie zu grob und
      // an den Rändern sogar falsch: Zu 2001 ist 1998 ein tadelloser
      // Ablenker, steht aber im 20. Jahrhundert. Was wirklich zählt, ist
      // der Abstand — und dass nichts angeboten wird, was noch gar nicht
      // passiert sein kann.
      for (final int jahr in <int>[1912, 1969, 1989, 2001, 2020, 2025]) {
        final VocabEntry karte = harvestDaily(
          DailyFeed(day: _tag, events: <DailyItem>[_ereignis(jahr, 'Etwas geschah')]),
          currentYear: 2026,
        ).single;
        for (final String ablenker in karte.distractors) {
          final int? falsch = int.tryParse(ablenker);
          expect(falsch, isNotNull, reason: ablenker);
          expect((falsch! - jahr).abs(), lessThanOrEqualTo(15),
              reason: '$ablenker liegt zu weit von $jahr entfernt');
          expect(falsch, lessThanOrEqualTo(2026),
              reason: '$ablenker liegt in der Zukunft');
        }
        expect(karte.distractors.toSet(), hasLength(3), reason: '$jahr');
      }
    });

    test('nimmt nie eine Nachricht mit', () {
      // Sie wäre in drei Wochen überholt — genau das sagt `canRemember`.
      final List<VocabEntry> ernte = harvestDaily(DailyFeed(day: _tag, 
        article: _artikel('Golfstrom'),
        news: <DailyItem>[_meldung, _meldung],
      ));
      expect(ernte, hasLength(1));
      expect(ernte.single.german, 'Golfstrom');
    });

    test('nimmt höchstens ein Ereignis, auch wenn zwölf dastehen', () {
      final List<VocabEntry> ernte = harvestDaily(DailyFeed(day: _tag, 
        article: _artikel('Golfstrom'),
        events: <DailyItem>[
          for (int i = 0; i < 12; i++) _ereignis(1900 + i, 'Ereignis $i'),
        ],
      ));
      expect(ernte, hasLength(2), reason: 'ein Artikel, ein Ereignis');
    });

    test('mehr Ereignisse auf Wunsch, aber nie mehr als da sind', () {
      final List<VocabEntry> ernte = harvestDaily(
        DailyFeed(day: _tag, events: <DailyItem>[_ereignis(1969, 'A'), _ereignis(1970, 'B')]),
        maxEvents: 5,
      );
      expect(ernte, hasLength(2));
    });

    test('derselbe Fund zweimal ergibt eine Karte', () {
      // Die id ist der Schlüssel des Lernstands; zwei gleiche Karten teilten
      // sich Stufe und Termin.
      final List<VocabEntry> ernte = harvestDaily(DailyFeed(day: _tag, 
        article: _artikel('Golfstrom'),
        events: <DailyItem>[_ereignis(1969, 'A'), _ereignis(1969, 'A')],
      ), maxEvents: 3);
      expect(ernte.map((VocabEntry e) => e.id).toSet(), hasLength(ernte.length));
    });

    test('ein leerer Tag bricht nicht', () {
      expect(harvestDaily(DailyFeed(day: _tag)), isEmpty);
      expect(harvestDaily(DailyFeed(day: _tag, news: <DailyItem>[_meldung])), isEmpty);
    });

    test('ein Ereignis ohne Jahr wird eine Begriffskarte, keine Frage', () {
      final List<VocabEntry> ernte =
          harvestDaily(DailyFeed(day: _tag, events: const <DailyItem>[
        DailyItem(
          kind: DailyItemKind.event,
          title: 'Irgendwann',
          text: 'Etwas ohne Jahreszahl.',
        ),
      ]));
      expect(ernte, hasLength(1));
      expect(ernte.single.question, isNull);
    });
  });

  group('Mit den echten abgelegten Antworten', () {
    test('kommt eine brauchbare Tagesration heraus', () async {
      final DailyFeedService service = await loadedFeed();
      final DailyFeed? feed = service.feed;
      expect(feed, isNotNull);

      final List<VocabEntry> ernte = harvestDaily(feed!, currentYear: 2026);
      expect(ernte, isNotEmpty);
      expect(ernte.length, lessThanOrEqualTo(2));

      for (final VocabEntry karte in ernte) {
        expect(karte.german.trim(), isNotEmpty);
        expect(karte.answer.trim(), isNotEmpty);
        expect(karte.isLanguage, isFalse, reason: 'Wissen, keine Vokabel');
        expect(karte.source, isNotNull);
        // Dieselbe Grenze wie im geschriebenen Bestand: Was länger ist,
        // passt nicht auf vier Antwortknöpfe.
        expect(karte.answer.length, lessThanOrEqualTo(60), reason: karte.answer);
        for (final String ablenker in karte.distractors) {
          expect(ablenker.length, lessThanOrEqualTo(60), reason: ablenker);
        }
      }
    });

    test('zweimal geerntet ergibt dieselben Karten', () async {
      // Sonst käme bei jedem Neuzeichnen eine neue Karte in den Bestand.
      final DailyFeedService service = await loadedFeed();
      final List<String> a = <String>[
        for (final VocabEntry e in harvestDaily(service.feed!)) e.id,
      ];
      final List<String> b = <String>[
        for (final VocabEntry e in harvestDaily(service.feed!)) e.id,
      ];
      expect(a, b);
    });
  });
}
