import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/models/daily_item.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/daily_feed.dart';

/// Ein Netz, das tut, was der Test sagt.
///
/// Die abgelegten Antworten sind echte, gekürzte Antworten der beiden Quellen
/// vom 10.09.2026 — geprüft wird also gegen das, was wirklich ankommt, nicht
/// gegen eine Vorstellung davon.
class FakeFeedBackend implements FeedBackend {
  FakeFeedBackend({required this.wikipedia, required this.news});

  FakeFeedBackend.ok()
      : wikipedia = FeedResponse(200, _read('wikipedia_feed.json')),
        news = FeedResponse(200, _read('tagesschau_news.json'));

  FeedResponse wikipedia;
  FeedResponse news;

  final List<Uri> calls = <Uri>[];

  @override
  Future<FeedResponse> get(Uri url) async {
    calls.add(url);
    return url.host == DailyFeedService.wikipediaHost ? wikipedia : news;
  }

  static String _read(String name) => File('test/data/$name').readAsStringSync();
}

Map<String, Object?> _fixture(String name) =>
    jsonDecode(FakeFeedBackend._read(name)) as Map<String, Object?>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  DailyFeedService serviceAt(DateTime now, FakeFeedBackend backend) =>
      DailyFeedService(backend: backend, clock: () => now);

  group('Auswertung der Antworten', () {
    test('liest den Artikel des Tages', () {
      final DailyItem? article =
          parseArticleOfTheDay(_fixture('wikipedia_feed.json')['tfa']);
      expect(article, isNotNull);
      expect(article!.title, 'Kragenhai');
      expect(article.kind, DailyItemKind.article);
      expect(article.text, contains('Kragenhai'));
      expect(article.url, startsWith('https://de.wikipedia.org/wiki/'));
    });

    test('liest „Was geschah heute" mit Jahreszahl', () {
      final List<DailyItem> events =
          parseOnThisDay(_fixture('wikipedia_feed.json')['onthisday']);
      expect(events, hasLength(3));
      expect(events.every((DailyItem e) => e.year != null), isTrue);
      expect(events.every((DailyItem e) => e.text.isNotEmpty), isTrue);
      expect(events.first.kind, DailyItemKind.event);
    });

    test('nimmt nur Meldungen mit Text und Verweis', () {
      final List<DailyItem> news =
          parseNews(_fixture('tagesschau_news.json')['news']);
      // Vier Meldungen; der Videobeitrag ohne ersten Satz fällt heraus.
      expect(news, hasLength(4));
      expect(news.every((DailyItem n) => n.url != null), isTrue);
      expect(
        news.any((DailyItem n) => n.title.startsWith('"Zum ersten Mal')),
        isFalse,
      );
    });

    test('ein fehlendes Feld verwirft einen Eintrag, nicht den Abschnitt', () {
      final List<DailyItem> events = parseOnThisDay(<Object?>[
        <String, Object?>{'text': 'Erstes Ereignis', 'year': 1900},
        <String, Object?>{'year': 1901}, // ohne Text
        <String, Object?>{'text': 'Drittes Ereignis'}, // ohne Jahr
        <String, Object?>{'text': 'Viertes Ereignis', 'year': 1902},
      ]);
      expect(events.map((DailyItem e) => e.year), <int>[1900, 1902]);
    });

    test('unerwartete Formen ergeben leere Abschnitte statt Fehler', () {
      expect(parseArticleOfTheDay('kein Objekt'), isNull);
      expect(parseArticleOfTheDay(null), isNull);
      expect(parseOnThisDay(<String, Object?>{}), isEmpty);
      expect(parseNews(42), isEmpty);
    });

    test('höchstens so viele, wie der Abschnitt zeigt', () {
      final List<Object?> viele = <Object?>[
        for (int i = 0; i < 30; i++)
          <String, Object?>{'text': 'Ereignis $i', 'year': 1900 + i},
      ];
      expect(parseOnThisDay(viele, max: 5), hasLength(5));
    });
  });

  group('Abruf', () {
    test('holt beide Quellen und legt sie ab', () async {
      final FakeFeedBackend backend = FakeFeedBackend.ok();
      final DailyFeedService service =
          serviceAt(DateTime(2026, 9, 10, 8), backend);
      await service.refresh();

      expect(service.status, FeedStatus.ready);
      expect(service.feed!.article, isNotNull);
      expect(service.feed!.events, isNotEmpty);
      expect(service.feed!.news, isNotEmpty);
      expect(service.feed!.day, DateTime(2026, 9, 10));
      expect(backend.calls, hasLength(2));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(DailyFeedService.cacheKey), isNotNull);
    });

    test('ruft am selben Tag kein zweites Mal ab', () async {
      final FakeFeedBackend backend = FakeFeedBackend.ok();
      final DailyFeedService service =
          serviceAt(DateTime(2026, 9, 10, 8), backend);
      await service.ensureFresh();
      await service.ensureFresh();
      expect(backend.calls, hasLength(2));
    });

    test('am nächsten Tag wieder', () async {
      final FakeFeedBackend backend = FakeFeedBackend.ok();
      await serviceAt(DateTime(2026, 9, 10, 8), backend).ensureFresh();

      // Neuer Dienst, neuer Tag — der Stand von gestern reicht nicht.
      final DailyFeedService morgen =
          serviceAt(DateTime(2026, 9, 11, 8), backend);
      await morgen.ensureFresh();
      expect(backend.calls, hasLength(4));
      expect(morgen.isStale, isFalse);
    });

    test('ohne Netz bleibt der letzte Stand mit seinem Datum stehen',
        () async {
      final FakeFeedBackend backend = FakeFeedBackend.ok();
      final DailyFeedService service =
          serviceAt(DateTime(2026, 9, 10, 8), backend);
      await service.refresh();
      final DailyItem? gestern = service.feed!.article;

      backend
        ..wikipedia = const FeedResponse.offline()
        ..news = const FeedResponse.offline();
      final DailyFeedService morgen =
          serviceAt(DateTime(2026, 9, 11, 8), backend);
      await morgen.ensureFresh();

      expect(morgen.status, FeedStatus.offline);
      expect(morgen.feed!.article!.title, gestern!.title);
      expect(morgen.feed!.day, DateTime(2026, 9, 10));
      expect(morgen.isStale, isTrue);
    });

    test('429 wird als Drosselung gemeldet, nicht als Fehler', () async {
      final FakeFeedBackend backend = FakeFeedBackend(
        wikipedia: const FeedResponse(429, ''),
        news: const FeedResponse(429, ''),
      );
      final DailyFeedService service =
          serviceAt(DateTime(2026, 9, 10, 8), backend);
      await service.refresh();
      expect(service.status, FeedStatus.rateLimited);
      expect(service.feed, isNull);
    });

    test('kaputtes JSON wirft nicht', () async {
      final FakeFeedBackend backend = FakeFeedBackend(
        wikipedia: const FeedResponse(200, '{das ist kein JSON'),
        news: const FeedResponse(200, '<html>Fehler</html>'),
      );
      final DailyFeedService service =
          serviceAt(DateTime(2026, 9, 10, 8), backend);
      await service.refresh();
      expect(service.status, FeedStatus.failed);
      expect(service.feed, isNull);
    });

    test('eine tote Quelle nimmt die andere nicht mit', () async {
      final FakeFeedBackend backend = FakeFeedBackend.ok()
        ..news = const FeedResponse.offline();
      final DailyFeedService service =
          serviceAt(DateTime(2026, 9, 10, 8), backend);
      await service.refresh();

      expect(service.status, FeedStatus.ready);
      expect(service.feed!.article, isNotNull);
      expect(service.feed!.news, isEmpty);
    });

    test('liest den abgelegten Stand ohne Netz', () async {
      final FakeFeedBackend backend = FakeFeedBackend.ok();
      await serviceAt(DateTime(2026, 9, 10, 8), backend).refresh();

      final FakeFeedBackend leer = FakeFeedBackend(
        wikipedia: const FeedResponse.offline(),
        news: const FeedResponse.offline(),
      );
      final DailyFeedService neu = serviceAt(DateTime(2026, 9, 10, 20), leer);
      await neu.load();

      expect(leer.calls, isEmpty);
      expect(neu.feed!.article!.title, 'Kragenhai');
      expect(neu.status, FeedStatus.ready);
    });
  });

  group('Adressen', () {
    test('Wikipedia: ein Aufruf mit zweistelligem Datum', () {
      final Uri url = DailyFeedService.wikipediaUrl(DateTime(2026, 9, 3));
      expect(url.toString(),
          'https://de.wikipedia.org/api/rest_v1/feed/featured/2026/09/03');
    });

    test('Tagesschau: ohne Schrägstrich am Ende', () {
      // Mit Schrägstrich antwortet der Server 308.
      expect(DailyFeedService.newsUrl().toString(),
          'https://www.tagesschau.de/api2u/news');
    });
  });

  group('Karten aus Funden', () {
    test('Nachrichten erzeugen nie einen Lerneintrag', () {
      final List<DailyItem> news =
          parseNews(_fixture('tagesschau_news.json')['news']);
      expect(news, isNotEmpty);
      expect(news.every((DailyItem n) => n.toCard() == null), isTrue);
      expect(news.every((DailyItem n) => !n.canRemember), isTrue);
    });

    test('ein Ereignis wird zur Jahresfrage mit drei Ablenkern', () {
      final DailyItem event =
          parseOnThisDay(_fixture('wikipedia_feed.json')['onthisday']).first;
      final VocabEntry? card = event.toCard(currentYear: 2026);

      expect(card, isNotNull);
      expect(card!.prompt, startsWith('In welchem Jahr:'));
      expect(card.answer, '${event.year}');
      expect(card.distractors, hasLength(3));
      expect(card.distractors, isNot(contains(card.answer)));
      expect(card.distractors.toSet(), hasLength(3));
      expect(card.explanation, event.text);
      expect(card.isLanguage, isFalse);
    });

    test('Ablenker liegen nie in der Zukunft', () {
      final List<String> years = DailyItem.yearDistractors(2026, 2026);
      expect(years, hasLength(3));
      for (final String year in years) {
        expect(int.parse(year), lessThanOrEqualTo(2026));
      }
    });

    test('Jahre vor der Zeitenwende werden ausgeschrieben', () {
      expect(DailyItem.formatYear(-44), '44 v. Chr.');
      expect(DailyItem.formatYear(1996), '1996');
    });

    test('der Artikel des Tages wird zur Begriffskarte', () {
      final DailyItem article =
          parseArticleOfTheDay(_fixture('wikipedia_feed.json')['tfa'])!;
      final VocabEntry card = article.toCard()!;

      expect(card.german, 'Kragenhai');
      expect(card.answer.length, lessThanOrEqualTo(92));
      expect(card.distractors, isEmpty);
      expect(card.source, contains('Wikipedia'));
    });
  });

  group('Speicherformat', () {
    test('überlebt den Weg durch JSON', () {
      final DailyFeed feed = DailyFeed(
        day: DateTime(2026, 9, 10),
        article: const DailyItem(
          kind: DailyItemKind.article,
          title: 'Kragenhai',
          text: 'Ein Hai.',
          subtitle: 'Art',
          url: 'https://example.org',
        ),
        events: const <DailyItem>[
          DailyItem(
              kind: DailyItemKind.event,
              title: 'UN',
              text: 'Etwas geschah.',
              year: 1996),
        ],
        news: const <DailyItem>[
          DailyItem(
              kind: DailyItemKind.news, title: 'Titel', text: 'Erster Satz.'),
        ],
      );

      final DailyFeed? zurueck =
          DailyFeed.fromJson(jsonDecode(jsonEncode(feed.toJson())));
      expect(zurueck, isNotNull);
      expect(zurueck!.day, feed.day);
      expect(zurueck.article!.title, 'Kragenhai');
      expect(zurueck.events.single.year, 1996);
      expect(zurueck.news.single.kind, DailyItemKind.news);
    });

    test('ein kaputter Eintrag kostet nur sich selbst', () {
      final DailyFeed? feed = DailyFeed.fromJson(<String, Object?>{
        'day': '2026-9-10',
        'events': <Object?>[
          <String, Object?>{'kind': 'event', 'title': 'A', 'text': 'gut'},
          <String, Object?>{'kind': 'event', 'title': 'B'}, // ohne Text
          'kein Objekt',
        ],
      });
      expect(feed, isNotNull);
      expect(feed!.events, hasLength(1));
      expect(feed.day, DateTime(2026, 9, 10));
    });

    test('ohne Datum ist der Stand wertlos und wird verworfen', () {
      expect(DailyFeed.fromJson(<String, Object?>{'events': <Object?>[]}),
          isNull);
    });
  });
}
