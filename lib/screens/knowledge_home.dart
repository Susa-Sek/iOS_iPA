import 'package:flutter/material.dart';

import '../data/knowledge/lessons.dart';
import '../models/daily_item.dart';
import '../models/vocabulary.dart';
import '../state/daily_feed.dart';
import '../state/learning_state.dart';
import '../state/lesson_store.dart';
import '../theme/app_theme.dart';
import '../widgets/subject_switch.dart';
import 'category_screen.dart';
import 'lesson_screen.dart';
import 'today_screen.dart';

/// Die Startseite im Fach Wissen.
///
/// Bewusst eine **andere** Seite als bei Arabisch. Dort ist das Maß das
/// gelernte Wort und der Weg die Wiederholung; hier ist das Maß das
/// verstandene Thema und der Weg die Lektion. Deshalb steht hier kein
/// Lernweg mit Wortlisten, keine Fälligkeitszahl und kein Tagesziel in
/// Antworten — sondern eine Lektion, der Tagesstoff und drei Fächer.
class KnowledgeHome extends StatefulWidget {
  const KnowledgeHome({super.key});

  @override
  State<KnowledgeHome> createState() => _KnowledgeHomeState();
}

class _KnowledgeHomeState extends State<KnowledgeHome> {
  bool _gefragt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gefragt) return;
    _gefragt = true;
    // Der Tagesstoff wird geholt, wenn dieses Fach offen ist — nicht beim
    // Start der App.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) DailyFeedScope.of(context).ensureFresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final LessonStore lessons = LessonScope.of(context);
    final ThemeData theme = Theme.of(context);
    final KnowledgeLesson? naechste = lessons.nextLesson(_lektionenIm(state));

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: const Text('Lernen'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.today_outlined),
                tooltip: 'Mehr von heute',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TodayScreen(),
                  ),
                ),
              ),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: SubjectSwitchHeader(
              MediaQuery.textScalerOf(context).scale(1),
            ),
          ),
          SliverToBoxAdapter(
            child: _LektionKarte(lesson: naechste, store: lessons),
          ),
          const SliverToBoxAdapter(child: _Tagesstoff()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.lg, Insets.xl, Insets.lg, Insets.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Fächer',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: Insets.sm),
                  // Bei großer Schrift lief die Zeile rechts über; sie darf
                  // schrumpfen, die Überschrift bleibt.
                  Flexible(
                    child: Text(
                      '${lessons.doneCount} von '
                      '${_alleLektionen(state).length} Lektionen',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => _FachKarte(
                group: state.groups[index],
                store: lessons,
              ),
              childCount: state.groups.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Insets.xxl)),
        ],
      ),
    );
  }

  List<KnowledgeLesson> _lektionenIm(LearningState state) => <KnowledgeLesson>[
        for (final CategoryGroup g in state.groups)
          for (final VocabCategory c in g.categories) ...lessonsOf(c),
      ];

  List<KnowledgeLesson> _alleLektionen(LearningState state) =>
      _lektionenIm(state);
}

/// Der eine große Griff: die Lektion, die als Nächstes dran ist.
class _LektionKarte extends StatelessWidget {
  const _LektionKarte({required this.lesson, required this.store});

  final KnowledgeLesson? lesson;
  final LessonStore store;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KnowledgeLesson? lektion = lesson;
    if (lektion == null) return const SizedBox.shrink();

    final bool schonMal = store.isDone(lektion.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.sm, Insets.lg, Insets.xs),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.primaryContainer,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LessonScreen(lesson: lektion),
            ),
          ),
          child: Padding(
            padding: Insets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.menu_book_outlined,
                        size: 18, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Text(
                        schonMal
                            ? 'Nochmal durchgehen'
                            : 'Lektion des Tages',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Text('5 Min',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        )),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                Text(
                  lektion.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  lektion.intro,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Artikel des Tages und „Was geschah heute" — der Grund, warum der
/// Tagesstoff hierher gehört und nicht in einen eigenen Bereich.
class _Tagesstoff extends StatelessWidget {
  const _Tagesstoff();

  @override
  Widget build(BuildContext context) {
    final DailyFeedService feed = DailyFeedScope.of(context);
    final DailyFeed? heute = feed.feed;
    if (heute == null) return const SizedBox.shrink();

    final DailyItem? artikel = heute.article;
    final DailyItem? ereignis =
        heute.events.isEmpty ? null : heute.events.first;
    if (artikel == null && ereignis == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.md, Insets.lg, 0),
      child: Column(
        children: <Widget>[
          if (artikel != null)
            _TagesZeile(
              icon: Icons.auto_stories_outlined,
              label: 'Artikel des Tages',
              titel: artikel.title,
            ),
          if (ereignis != null) ...<Widget>[
            const SizedBox(height: Insets.sm),
            _TagesZeile(
              icon: Icons.history_edu,
              label: ereignis.year == null
                  ? 'Was geschah heute'
                  : 'Was geschah heute · ${DailyItem.formatYear(ereignis.year!)}',
              titel: ereignis.text,
            ),
          ],
        ],
      ),
    );
  }
}

class _TagesZeile extends StatelessWidget {
  const _TagesZeile({
    required this.icon,
    required this.label,
    required this.titel,
  });

  final IconData icon;
  final String label;
  final String titel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TodayScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Insets.md, vertical: Insets.md),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        )),
                    const SizedBox(height: 2),
                    Text(titel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: Insets.sm),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ein Fach mit seinen Themen — gezählt in Lektionen, nicht in Karten.
class _FachKarte extends StatelessWidget {
  const _FachKarte({required this.group, required this.store});

  final CategoryGroup group;
  final LessonStore store;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int gesamt = <int>[
      for (final VocabCategory c in group.categories) lessonsOf(c).length,
    ].fold(0, (int a, int b) => a + b);
    final int fertig = <int>[
      for (final VocabCategory c in group.categories) store.doneIn(c),
    ].fold(0, (int a, int b) => a + b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(group.icon, color: theme.colorScheme.primary),
          title: Text(group.name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('$fertig von $gesamt Lektionen',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: gesamt == 0 ? 0 : fertig / gesamt,
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
          children: <Widget>[
            for (final VocabCategory category in group.categories)
              _ThemaZeile(category: category, store: store),
            const SizedBox(height: Insets.sm),
          ],
        ),
      ),
    );
  }
}

class _ThemaZeile extends StatelessWidget {
  const _ThemaZeile({required this.category, required this.store});

  final VocabCategory category;
  final LessonStore store;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<KnowledgeLesson> lektionen = lessonsOf(category);
    final int fertig = store.doneIn(category);
    final bool verstanden = store.isUnderstood(category);

    return ListTile(
      leading: Icon(category.icon, color: category.color),
      title: Text(category.name),
      subtitle: Text(verstanden
          ? 'Verstanden'
          : '$fertig von ${lektionen.length} Lektionen'),
      trailing: verstanden
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CategoryScreen(category: category),
        ),
      ),
    );
  }
}
