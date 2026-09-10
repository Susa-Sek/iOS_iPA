import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_item.dart';

/// Was bei einem Abruf herauskam.
///
/// Der Rückgabewert trägt den Status mit, weil 429 („zu viele Anfragen") und
/// „kein Netz" verschieden zu behandeln sind: das eine heißt warten, das
/// andere heißt, den letzten Stand zu zeigen.
@immutable
class FeedResponse {
  const FeedResponse(this.status, this.body);

  /// Kein Netz, Zeitüberschreitung, abgebrochene Verbindung.
  const FeedResponse.offline() : this(0, '');

  final int status;
  final String body;

  bool get isOk => status == 200 && body.isNotEmpty;
  bool get isRateLimited => status == 429;
  bool get isOffline => status == 0;
}

/// Der Teil des Netzes, den die App benutzt.
///
/// Hinter einer Schnittstelle wie `SpeechBackend` und `ReminderBackend`, damit
/// der Bereich „Heute" ohne Netz prüfbar ist — gegen abgelegte Antworten
/// statt gegen die Laune eines fremden Servers.
abstract class FeedBackend {
  Future<FeedResponse> get(Uri url);
}

/// Der wirkliche Abruf.
class HttpFeedBackend implements FeedBackend {
  HttpFeedBackend({http.Client? client, this.timeout = const Duration(seconds: 12)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// Wikimedia verlangt eine erkennbare Kennung mit Kontaktmöglichkeit;
  /// anonyme Massenabrufe werden gedrosselt. Enthält bewusst keine
  /// persönlichen Daten.
  static const String userAgent =
      'TaeglichKlueger/1.6 (https://github.com/susa-sek/ios_ipa)';

  @override
  Future<FeedResponse> get(Uri url) async {
    try {
      final http.Response response = await _client.get(
        url,
        headers: const <String, String>{
          'User-Agent': userAgent,
          'Accept': 'application/json',
        },
      ).timeout(timeout);
      return FeedResponse(response.statusCode, utf8.decode(response.bodyBytes,
          allowMalformed: true));
    } catch (error) {
      debugPrint('Abruf fehlgeschlagen ($url): $error');
      return const FeedResponse.offline();
    }
  }

  void dispose() => _client.close();
}

/// Wie der letzte Abruf ausgegangen ist.
enum FeedStatus {
  /// Noch nichts versucht.
  idle,
  loading,
  ready,

  /// Kein Netz — gezeigt wird der letzte Stand mit seinem Datum.
  offline,

  /// Die Quelle drosselt (429). Später noch einmal.
  rateLimited,

  /// Antwort kam an, war aber nicht zu gebrauchen.
  failed,
}

/// Holt die Inhalte des Bereichs „Heute" und merkt sie sich für den Tag.
///
/// Der Feed ist Beiwerk, kein Fundament: Fällt er aus, lernt man weiter wie
/// bisher. Deshalb wirft hier nichts — jeder Fehler endet in einem [status]
/// und dem letzten bekannten Stand.
class DailyFeedService extends ChangeNotifier {
  DailyFeedService({
    FeedBackend? backend,
    DateTime Function()? clock,
  })  : _backend = backend ?? HttpFeedBackend(),
        _now = clock ?? DateTime.now;

  final FeedBackend _backend;
  final DateTime Function() _now;

  /// Der Schlüssel folgt dem Muster der übrigen — siehe `naming_test.dart`:
  /// Das Präfix bleibt, auch wenn die App anders heißt.
  static const String cacheKey = 'arabisch_lernen.feed.v1';

  static const String wikipediaHost = 'de.wikipedia.org';
  static const String tagesschauHost = 'www.tagesschau.de';

  /// Wie viele Einträge je Abschnitt gezeigt werden.
  static const int maxEvents = 5;
  static const int maxNews = 8;

  DailyFeed? _feed;
  DateTime? _fetchedAt;
  FeedStatus _status = FeedStatus.idle;
  bool _cacheRead = false;

  DailyFeed? get feed => _feed;
  DateTime? get fetchedAt => _fetchedAt;
  FeedStatus get status => _status;
  bool get isLoading => _status == FeedStatus.loading;

  /// Ob der gezeigte Stand von einem früheren Tag ist.
  bool get isStale {
    final DailyFeed? feed = _feed;
    return feed != null && !_isSameDay(feed.day, _now());
  }

  /// Liest den gespeicherten Stand. Kein Netz, kein Warten beim Start.
  Future<void> load() async {
    if (_cacheRead) return;
    _cacheRead = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(cacheKey);
    if (raw == null) return;
    try {
      final Object? json = jsonDecode(raw);
      if (json is! Map) return;
      _feed = DailyFeed.fromJson(json['feed']);
      _fetchedAt = DateTime.tryParse(json['fetchedAt'] as String? ?? '');
      if (_feed != null) _status = FeedStatus.ready;
    } catch (error) {
      debugPrint('Gespeicherter Tagesinhalt unlesbar: $error');
    }
    notifyListeners();
  }

  /// Wird beim Öffnen des Bereichs aufgerufen: holt nur, was fehlt.
  Future<void> ensureFresh() async {
    await load();
    if (_status == FeedStatus.loading) return;
    if (_feed != null && !isStale) return;
    await refresh();
  }

  /// Holt beide Quellen. Eine kaputte Quelle nimmt die andere nicht mit.
  Future<void> refresh() async {
    if (_status == FeedStatus.loading) return;
    await load();
    _status = FeedStatus.loading;
    notifyListeners();

    final DateTime today = _dayOf(_now());
    final List<FeedResponse> answers = await Future.wait<FeedResponse>(
      <Future<FeedResponse>>[
        _backend.get(wikipediaUrl(today)),
        _backend.get(newsUrl()),
      ],
    );
    final FeedResponse wiki = answers[0];
    final FeedResponse news = answers[1];

    final Map<String, Object?>? wikiJson = _decode(wiki);
    final Map<String, Object?>? newsJson = _decode(news);

    final DailyItem? article =
        wikiJson == null ? null : parseArticleOfTheDay(wikiJson['tfa']);
    final List<DailyItem> events = wikiJson == null
        ? const <DailyItem>[]
        : parseOnThisDay(wikiJson['onthisday'], max: maxEvents);
    final List<DailyItem> items = newsJson == null
        ? const <DailyItem>[]
        : parseNews(newsJson['news'], max: maxNews);

    final DailyFeed fresh = DailyFeed(
      day: today,
      article: article,
      events: events,
      news: items,
    );

    if (fresh.isEmpty) {
      // Nichts Brauchbares: den letzten Stand behalten und sagen, warum.
      _status = _statusOfFailure(<FeedResponse>[wiki, news]);
      notifyListeners();
      return;
    }

    _feed = fresh;
    _fetchedAt = _now();
    _status = FeedStatus.ready;
    notifyListeners();
    await _save();
  }

  static FeedStatus _statusOfFailure(List<FeedResponse> answers) {
    if (answers.any((FeedResponse r) => r.isRateLimited)) {
      return FeedStatus.rateLimited;
    }
    if (answers.every((FeedResponse r) => r.isOffline)) {
      return FeedStatus.offline;
    }
    return FeedStatus.failed;
  }

  Map<String, Object?>? _decode(FeedResponse response) {
    if (!response.isOk) return null;
    try {
      final Object? json = jsonDecode(response.body);
      return json is Map<String, Object?> ? json : null;
    } catch (error) {
      debugPrint('Antwort war kein brauchbares JSON: $error');
      return null;
    }
  }

  Future<void> _save() async {
    final DailyFeed? feed = _feed;
    if (feed == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      cacheKey,
      jsonEncode(<String, Object?>{
        'feed': feed.toJson(),
        'fetchedAt': (_fetchedAt ?? _now()).toIso8601String(),
      }),
    );
  }

  /// Ein Aufruf für Artikel des Tages **und** „Was geschah heute" — der
  /// getrennte `onthisday`-Aufruf liefert dieselben Ereignisse in 641 KB
  /// statt in einem Bruchteil davon.
  static Uri wikipediaUrl(DateTime day) => Uri.https(
        wikipediaHost,
        '/api/rest_v1/feed/featured/${day.year}/'
            '${_two(day.month)}/${_two(day.day)}',
      );

  /// Ohne Schrägstrich am Ende — mit einem antwortet der Server 308.
  static Uri newsUrl() => Uri.https(tagesschauHost, '/api2u/news');

  static String _two(int value) => value.toString().padLeft(2, '0');

  static DateTime _dayOf(DateTime time) =>
      DateTime(time.year, time.month, time.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    final FeedBackend backend = _backend;
    if (backend is HttpFeedBackend) backend.dispose();
    super.dispose();
  }
}

// ---- Auswertung der Antworten ------------------------------------------
//
// Jedes Feld wird einzeln geprüft. Fehlt eines, fällt der einzelne Eintrag
// weg — nicht der ganze Abschnitt und schon gar nicht der ganze Tag.

/// Der Artikel des Tages aus dem Feld `tfa`.
DailyItem? parseArticleOfTheDay(Object? json) {
  if (json is! Map) return null;
  final String? title = _string(json['normalizedtitle']) ?? _string(json['title']);
  final String? extract = _string(json['extract']);
  if (title == null || extract == null) return null;
  return DailyItem(
    kind: DailyItemKind.article,
    title: title.replaceAll('_', ' '),
    text: extract,
    subtitle: _string(json['description']),
    url: _pageUrl(json['content_urls']),
    imageUrl: _string((json['thumbnail'] as Map?)?['source']),
  );
}

/// „Was geschah heute" aus dem Feld `onthisday`.
List<DailyItem> parseOnThisDay(Object? json, {int max = 5}) {
  if (json is! List) return const <DailyItem>[];
  final List<DailyItem> events = <DailyItem>[];
  for (final Object? entry in json) {
    if (events.length >= max) break;
    if (entry is! Map) continue;
    final String? text = _string(entry['text']);
    final Object? year = entry['year'];
    if (text == null || year is! int) continue;
    final Map<String, Object?>? page = _firstPage(entry['pages']);
    events.add(DailyItem(
      kind: DailyItemKind.event,
      title: _string(page?['normalizedtitle'])?.replaceAll('_', ' ') ??
          DailyItem.formatYear(year),
      text: text,
      year: year,
      url: _pageUrl(page?['content_urls']),
      imageUrl: _string((page?['thumbnail'] as Map?)?['source']),
    ));
  }
  return events;
}

/// Die Meldungen aus `api2u/news`.
///
/// Nur ausgeschriebene Meldungen mit erstem Satz und Verweis: Videobeiträge
/// tragen keinen Text, aus dem sich etwas lesen ließe.
List<DailyItem> parseNews(Object? json, {int max = 8}) {
  if (json is! List) return const <DailyItem>[];
  final List<DailyItem> news = <DailyItem>[];
  for (final Object? entry in json) {
    if (news.length >= max) break;
    if (entry is! Map) continue;
    if (entry['type'] != 'story') continue;
    final String? title = _string(entry['title']);
    final String? first = _string(entry['firstSentence']);
    final String? url = _string(entry['shareURL']) ?? _string(entry['detailsweb']);
    if (title == null || first == null || url == null) continue;
    news.add(DailyItem(
      kind: DailyItemKind.news,
      title: title,
      text: first,
      subtitle: _string(entry['topline']),
      url: url,
    ));
  }
  return news;
}

Map<String, Object?>? _firstPage(Object? pages) {
  if (pages is! List || pages.isEmpty) return null;
  final Object? first = pages.first;
  return first is Map<String, Object?> ? first : null;
}

String? _pageUrl(Object? contentUrls) {
  if (contentUrls is! Map) return null;
  final Object? desktop = contentUrls['desktop'];
  if (desktop is! Map) return null;
  return _string(desktop['page']);
}

String? _string(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Macht den Dienst im Baum verfügbar.
class DailyFeedScope extends InheritedNotifier<DailyFeedService> {
  const DailyFeedScope({
    super.key,
    required DailyFeedService service,
    required super.child,
  }) : super(notifier: service);

  static DailyFeedService of(BuildContext context) {
    final DailyFeedScope? scope =
        context.dependOnInheritedWidgetOfExactType<DailyFeedScope>();
    assert(scope != null, 'Kein DailyFeedScope im Baum');
    return scope!.notifier!;
  }
}
