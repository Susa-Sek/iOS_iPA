import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_item.dart';
import '../models/vocabulary.dart';
import '../state/custom_cards.dart';
import '../state/daily_feed.dart';
import '../theme/app_theme.dart';

/// Der Bereich „Heute": jeden Tag etwas Neues, das nicht im Programm steht.
///
/// Bewusst kein Pflichtprogramm — die Inhalte kommen von fremden Servern und
/// können ausbleiben. Wer hier etwas findet, das er behalten will, legt es
/// mit einem Tippen unter „Meine Karten" ab; von dort läuft es durch dieselbe
/// Wiederholung wie alles andere.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Erst beim Öffnen holen, nicht beim Start der App: Wer nie hierher
    // kommt, soll auch keine Abrufe auslösen.
    if (_asked) return;
    _asked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) DailyFeedScope.of(context).ensureFresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DailyFeedService service = DailyFeedScope.of(context);
    final DailyFeed? feed = service.feed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heute'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Neu laden',
            onPressed: service.isLoading ? null : service.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: service.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Insets.lg, Insets.sm, Insets.lg, Insets.xxl),
          children: <Widget>[
            _StatusLine(service: service),
            if (feed == null) ...<Widget>[
              const SizedBox(height: Insets.xl),
              _EmptyHint(service: service),
            ] else ...<Widget>[
              if (feed.article case final DailyItem article) ...<Widget>[
                const SizedBox(height: Insets.lg),
                const _SectionTitle('Artikel des Tages', Icons.auto_stories),
                const SizedBox(height: Insets.sm),
                _ArticleCard(item: article),
              ],
              if (feed.events.isNotEmpty) ...<Widget>[
                const SizedBox(height: Insets.xl),
                const _SectionTitle('Was geschah heute', Icons.history_edu),
                const SizedBox(height: Insets.sm),
                for (final DailyItem event in feed.events) ...<Widget>[
                  _EventCard(item: event),
                  const SizedBox(height: Insets.sm),
                ],
              ],
              if (feed.news.isNotEmpty) ...<Widget>[
                const SizedBox(height: Insets.xl),
                const _SectionTitle('Nachrichten', Icons.newspaper),
                const SizedBox(height: Insets.sm),
                for (final DailyItem item in feed.news) ...<Widget>[
                  _NewsCard(item: item),
                  const SizedBox(height: Insets.sm),
                ],
              ],
              const SizedBox(height: Insets.xl),
              const _Attribution(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Datum und Stand — die eine Zeile, die sagt, wie frisch das hier ist.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.service});

  final DailyFeedService service;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DailyFeed? feed = service.feed;
    final DateTime day = feed?.day ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(_longDate(day), style: theme.textTheme.titleMedium),
        const SizedBox(height: Insets.xs),
        Row(
          children: <Widget>[
            if (service.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: Insets.sm),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Expanded(
              child: Text(
                _statusText(service),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _statusText(DailyFeedService service) => switch (service.status) {
        FeedStatus.loading => 'Wird geladen …',
        FeedStatus.offline when service.feed != null =>
          'Kein Netz — letzter Stand vom ${_shortDate(service.feed!.day)}',
        FeedStatus.offline => 'Kein Netz.',
        FeedStatus.rateLimited =>
          'Die Quelle drosselt gerade. Später noch einmal versuchen.',
        FeedStatus.failed => 'Die Quelle war nicht zu erreichen.',
        FeedStatus.ready when service.isStale =>
          'Stand vom ${_shortDate(service.feed!.day)}',
        FeedStatus.ready => 'Frisch geladen',
        FeedStatus.idle => 'Noch nichts geladen',
      };

  static const List<String> _months = <String>[
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  static const List<String> _days = <String>[
    'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
    'Freitag', 'Samstag', 'Sonntag',
  ];

  static String _longDate(DateTime day) =>
      '${_days[day.weekday - 1]}, ${day.day}. ${_months[day.month - 1]}';

  static String _shortDate(DateTime day) =>
      '${day.day}.${day.month}.${day.year}';
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.service});

  final DailyFeedService service;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Icon(Icons.wb_sunny_outlined,
            size: 48, color: theme.colorScheme.outline),
        const SizedBox(height: Insets.md),
        Text(
          service.isLoading
              ? 'Die Inhalte des Tages werden geholt.'
              : 'Noch keine Inhalte für heute.',
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.sm),
        Text(
          'Dieser Bereich braucht Netz. Alles andere in der App '
          'funktioniert auch ohne.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.lg),
        if (!service.isLoading)
          OutlinedButton.icon(
            onPressed: service.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.item});

  final DailyItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (item.imageUrl case final String url) _CardImage(url: url),
          Padding(
            padding: Insets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: theme.textTheme.titleMedium),
                if (item.subtitle case final String subtitle) ...<Widget>[
                  const SizedBox(height: Insets.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: Insets.md),
                Text(
                  item.text,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Insets.md),
                _ItemActions(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ein Bild darf fehlen, ohne dass die Karte kaputtgeht.
class _CardImage extends StatelessWidget {
  const _CardImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? trace) =>
            const SizedBox.shrink(),
        loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? progress) =>
            progress == null
                ? child
                : ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const SizedBox.expand(),
                  ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.item});

  final DailyItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: Insets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (item.year case final int year)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm, vertical: Insets.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: Radii.chipShape,
                ),
                child: Text(
                  DailyItem.formatYear(year),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            const SizedBox(height: Insets.sm),
            Text(item.text, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Insets.md),
            _ItemActions(item: item),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final DailyItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: Insets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (item.subtitle case final String topline)
              Text(
                topline.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.6,
                ),
              ),
            const SizedBox(height: Insets.xs),
            Text(item.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: Insets.sm),
            Text(
              item.text,
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Insets.md),
            _ItemActions(item: item),
          ],
        ),
      ),
    );
  }
}

/// Merken und Verweis kopieren.
///
/// Kopieren statt Öffnen: Ein Browseraufruf bräuchte eine zweite
/// Plattform-Abhängigkeit, und der Bereich soll die App nicht schwerer machen
/// als nötig.
class _ItemActions extends StatelessWidget {
  const _ItemActions({required this.item});

  final DailyItem item;

  @override
  Widget build(BuildContext context) {
    final CustomCardStore store = CustomCardScope.of(context);
    final VocabEntry? card = item.toCard();
    final bool saved = card != null && store.contains(card.id);

    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: <Widget>[
        if (card != null)
          saved
              ? TextButton.icon(
                  onPressed: () => _forget(context, store, card),
                  icon: const Icon(Icons.bookmark, size: 18),
                  label: const Text('Gemerkt'),
                )
              : TextButton.icon(
                  onPressed: () => _remember(context, store, card),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Als Karte merken'),
                ),
        if (item.url case final String url)
          TextButton.icon(
            onPressed: () => _copy(context, url),
            icon: const Icon(Icons.link, size: 18),
            label: Text('${item.kind.sourceName} öffnen'),
          ),
      ],
    );
  }

  static Future<void> _remember(
      BuildContext context, CustomCardStore store, VocabEntry card) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool added = await store.add(card);
    messenger.showSnackBar(SnackBar(
      content: Text(added
          ? 'Unter „Meine Karten" abgelegt.'
          : 'Die Karte hast du schon.'),
    ));
  }

  static Future<void> _forget(
      BuildContext context, CustomCardStore store, VocabEntry card) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await store.remove(card.id);
    messenger.showSnackBar(
      const SnackBar(content: Text('Karte entfernt.')),
    );
  }

  static Future<void> _copy(BuildContext context, String url) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(const SnackBar(
      content: Text('Verweis kopiert — im Browser einfügen.'),
    ));
  }
}

/// Wikipedia steht unter CC BY-SA; das gehört sichtbar dorthin, wo der Text
/// steht, nicht in ein Menü.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      'Artikel des Tages und „Was geschah heute": Wikipedia, CC BY-SA 4.0. '
      'Nachrichten: tagesschau.de — Überschrift und erster Satz.',
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
