import 'package:flutter/foundation.dart';

import 'vocabulary.dart';

/// Woher ein Fund im Bereich „Heute" stammt.
enum DailyItemKind {
  /// Wikipedia: Artikel des Tages.
  article,

  /// Wikipedia: Was geschah heute.
  event,

  /// Tagesschau: eine Meldung.
  news;

  String get sourceName => switch (this) {
        DailyItemKind.article || DailyItemKind.event => 'Wikipedia',
        DailyItemKind.news => 'tagesschau.de',
      };

  /// Wikipedia steht unter CC BY-SA — das muss sichtbar sein, wo der Text
  /// steht, nicht im Kleingedruckten.
  String? get license => switch (this) {
        DailyItemKind.article || DailyItemKind.event => 'CC BY-SA 4.0',
        DailyItemKind.news => null,
      };
}

/// Ein einzelner Fund des Tages.
///
/// Bewusst flach und aus lauter einzeln optionalen Feldern gebaut: Fehlt in
/// der Antwort einer Quelle ein Feld, verwirft [DailyItem.fromJson] genau
/// diesen Eintrag — nicht den ganzen Tag.
@immutable
class DailyItem {
  const DailyItem({
    required this.kind,
    required this.title,
    required this.text,
    this.subtitle,
    this.url,
    this.imageUrl,
    this.year,
  });

  final DailyItemKind kind;

  /// Die Überschrift — Artikelname, Jahreszahl oder Meldungstitel.
  final String title;

  /// Der Fließtext: Auszug, Ereignis oder erster Satz der Meldung.
  final String text;

  /// Eine Zeile darüber: Kurzbeschreibung des Artikels, Dachzeile der Meldung.
  final String? subtitle;

  final String? url;
  final String? imageUrl;

  /// Nur bei „Was geschah heute".
  final int? year;

  /// Ob sich der Fund als Lernkarte merken lässt.
  ///
  /// Nachrichten nicht: Sie sind morgen überholt und hätten in einer
  /// Wiederholung nach drei Wochen nichts mehr zu suchen.
  bool get canRemember => kind != DailyItemKind.news;

  /// Der Fund als Lernkarte — `null`, wo das nicht zulässig ist.
  ///
  /// Ein Ereignis wird zur Jahresfrage: Das ist die Frage, die man später
  /// wirklich beantworten können will, und sie bringt drei plausible
  /// Falschantworten mit. Der Artikel des Tages wird zur Begriffskarte.
  VocabEntry? toCard({int? currentYear}) {
    if (!canRemember) return null;
    final String quelle =
        url == null ? kind.sourceName : '${kind.sourceName} · $url';

    final int? year = this.year;
    if (kind == DailyItemKind.event && year != null) {
      return VocabEntry.question(
        'In welchem Jahr: ${_shorten(text, 120)}',
        formatYear(year),
        distractors: yearDistractors(year, currentYear ?? DateTime.now().year),
        explanation: text,
        source: quelle,
      );
    }

    return VocabEntry.fact(
      title,
      _shorten(subtitle?.isNotEmpty == true ? subtitle! : text, 90),
      explanation: text,
      source: quelle,
    );
  }

  /// Drei Jahreszahlen in der Nähe der richtigen — nah genug, dass Raten
  /// nicht reicht, und nie in der Zukunft.
  static List<String> yearDistractors(int year, int currentYear) {
    const List<int> steps = <int>[3, 7, 12];
    final List<int> years = <int>[];
    for (int i = 0; i < steps.length; i++) {
      int candidate = i.isEven ? year - steps[i] : year + steps[i];
      if (candidate > currentYear) candidate = year - steps[i];
      if (candidate == year || years.contains(candidate)) {
        candidate = year - steps[i] - 1;
      }
      years.add(candidate);
    }
    return <String>[for (final int y in years) formatYear(y)];
  }

  /// Jahreszahlen vor der Zeitenwende kommen negativ an.
  static String formatYear(int year) =>
      year < 0 ? '${-year} v. Chr.' : '$year';

  /// Kürzt auf ganze Wörter, damit die Antwortseite einer Karte in eine
  /// Zeile passt und im Quiz nicht als Textwand erscheint.
  static String _shorten(String text, int max) {
    final String clean = text.trim();
    if (clean.length <= max) return clean;
    final int cut = clean.lastIndexOf(' ', max);
    return '${clean.substring(0, cut < max ~/ 2 ? max : cut)} …';
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind.name,
        'title': title,
        'text': text,
        if (subtitle != null) 'subtitle': subtitle,
        if (url != null) 'url': url,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (year != null) 'year': year,
      };

  static DailyItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final DailyItemKind? kind = _kindNamed(json['kind']);
    final String? title = _text(json['title']);
    final String? text = _text(json['text']);
    if (kind == null || title == null || text == null) return null;
    return DailyItem(
      kind: kind,
      title: title,
      text: text,
      subtitle: _text(json['subtitle']),
      url: _text(json['url']),
      imageUrl: _text(json['imageUrl']),
      year: json['year'] is int ? json['year'] as int : null,
    );
  }

  static DailyItemKind? _kindNamed(Object? name) {
    for (final DailyItemKind kind in DailyItemKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Alles, was der Bereich „Heute" an einem Tag zeigt.
@immutable
class DailyFeed {
  const DailyFeed({
    required this.day,
    this.article,
    this.events = const <DailyItem>[],
    this.news = const <DailyItem>[],
  });

  /// Der Tag, für den die Inhalte geholt wurden — ohne Uhrzeit.
  final DateTime day;

  final DailyItem? article;
  final List<DailyItem> events;
  final List<DailyItem> news;

  bool get isEmpty => article == null && events.isEmpty && news.isEmpty;

  /// Alles, was sich merken lässt — der Vorrat für „Als Karte merken".
  List<DailyItem> get rememberable => <DailyItem>[
        if (article != null) article!,
        ...events,
      ];

  DailyFeed copyWith({DailyItem? article, List<DailyItem>? news}) => DailyFeed(
        day: day,
        article: article ?? this.article,
        events: events,
        news: news ?? this.news,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'day': '${day.year}-${day.month}-${day.day}',
        if (article != null) 'article': article!.toJson(),
        'events': <Object?>[for (final DailyItem e in events) e.toJson()],
        'news': <Object?>[for (final DailyItem n in news) n.toJson()],
      };

  static DailyFeed? fromJson(Object? json) {
    if (json is! Map) return null;
    final DateTime? day = _day(json['day']);
    if (day == null) return null;
    return DailyFeed(
      day: day,
      article: DailyItem.fromJson(json['article']),
      events: _items(json['events']),
      news: _items(json['news']),
    );
  }

  static List<DailyItem> _items(Object? json) {
    if (json is! List) return const <DailyItem>[];
    return <DailyItem>[
      for (final Object? entry in json)
        if (DailyItem.fromJson(entry) case final DailyItem item) item,
    ];
  }

  static DateTime? _day(Object? value) {
    if (value is! String) return null;
    final List<String> parts = value.split('-');
    if (parts.length != 3) return null;
    final int? y = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    final int? d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
