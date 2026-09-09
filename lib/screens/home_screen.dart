import 'package:flutter/material.dart';

import '../data/curriculum.dart';
import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import 'alphabet_screen.dart';
import 'build_word_screen.dart';
import 'category_screen.dart';
import 'flashcard_screen.dart';
import 'matching_screen.dart';
import 'quiz_screen.dart';
import 'quran_screen.dart';
import 'search_screen.dart';
import 'verbs_screen.dart';

/// Start screen: progress at a glance, the training modes and the list of
/// vocabulary categories.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: const Text('Arabisch lernen'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Suchen',
                onPressed: () => _push(context, const SearchScreen()),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  switch (value) {
                    case 'goal':
                      _editGoal(context, state);
                      break;
                    case 'reset':
                      _confirmReset(context, state);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'goal',
                    child: Text('Tagesziel ändern'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'reset',
                    child: Text('Fortschritt zurücksetzen'),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(child: _TodayCard(state: state)),
          SliverToBoxAdapter(child: _ProgressCard(state: state)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Üben',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 122,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  _ModeCard(
                    icon: Icons.style_outlined,
                    label: 'Karteikarten',
                    hint: 'Aufdecken',
                    onTap: () => _push(
                      context,
                      const FlashcardScreen(title: 'Alle Wörter'),
                    ),
                  ),
                  _ModeCard(
                    icon: Icons.quiz_outlined,
                    label: 'Quiz',
                    hint: '4 Antworten',
                    onTap: () => _push(
                      context,
                      const QuizScreen(title: 'Alle Wörter'),
                    ),
                  ),
                  _ModeCard(
                    icon: Icons.compare_arrows,
                    label: 'Zuordnen',
                    hint: 'Paare finden',
                    onTap: () => _push(
                      context,
                      const MatchingScreen(title: 'Alle Wörter'),
                    ),
                  ),
                  _ModeCard(
                    icon: Icons.grid_view,
                    label: 'Wort bauen',
                    hint: 'Buchstaben',
                    onTap: () => _push(
                      context,
                      const BuildWordScreen(title: 'Alle Wörter'),
                    ),
                  ),
                  _ModeCard(
                    icon: Icons.abc,
                    label: 'Alphabet',
                    hint: '28 Buchstaben',
                    onTap: () => _push(context, const AlphabetScreen()),
                  ),
                  _ModeCard(
                    icon: Icons.table_chart_outlined,
                    label: 'Verben',
                    hint: 'beugen',
                    onTap: () => _push(context, const VerbsScreen()),
                  ),
                  _ModeCard(
                    icon: Icons.menu_book_outlined,
                    label: 'Quran',
                    hint: 'Suren & Wurzeln',
                    onTap: () => _push(context, const QuranScreen()),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: <Widget>[
                  Text(
                    'Lernweg',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${state.totalCount} Wörter',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => _GroupCard(
                  group: kGroups[index],
                  state: state,
                  initiallyOpen: index == 0,
                ),
                childCount: kGroups.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _editGoal(BuildContext context, LearningState state) async {
    const List<int> options = <int>[5, 10, 20, 30, 50];
    final int? goal = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Tagesziel'),
        children: <Widget>[
          for (final int option in options)
            ListTile(
              leading: Icon(option == state.dailyGoal
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: Text('$option Antworten pro Tag'),
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    );
    if (goal != null) await state.setDailyGoal(goal);
  }

  Future<void> _confirmReset(BuildContext context, LearningState state) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Fortschritt zurücksetzen?'),
        content: const Text(
          'Alle gespeicherten Lernstände, Termine und Ergebnisse werden '
          'gelöscht. Das lässt sich nicht rückgängig machen.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
    if (yes ?? false) await state.reset();
  }
}

/// The daily routine: what is due today, the goal, and the day streak.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state});

  final LearningState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int due = state.dueCount;
    final int streak = state.dayStreak;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.today_outlined,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Heute',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (streak > 0)
                  Row(
                    children: <Widget>[
                      const Text('🔥'),
                      const SizedBox(width: 4),
                      Text(
                        '$streak ${streak == 1 ? "Tag" : "Tage"}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              due == 0
                  ? 'Alles wiederholt. Neue Wörter findest du in den Themen.'
                  : '$due ${due == 1 ? "Wort wartet" : "Wörter warten"} '
                      'auf eine Wiederholung.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.goalProgress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tagesziel: ${state.answeredToday} / ${state.dailyGoal} '
              'Antworten${state.goalReached ? " · geschafft" : ""}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (due > 0) ...<Widget>[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Jetzt wiederholen'),
                  onPressed: () => HomeScreen._push(
                    context,
                    FlashcardScreen(
                      entries: state.dueEntries(),
                      title: 'Heute fällig',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state});

  final LearningState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int percent = (state.overallProgress * 100).round();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: state.overallProgress,
                      strokeWidth: 7,
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  Text('$percent%', style: theme.textTheme.labelLarge),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Dein Fortschritt',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.learnedCount} von ${state.totalCount} Wörtern '
                    'sitzen, ${state.startedCount} sind angefangen',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (state.answered > 0) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      '${state.correct} von ${state.answered} Antworten '
                      'richtig',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: 124,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One area of the learning path: a headline with its own progress, and the
/// themes inside it. Collapsed by default so ~30 themes stay manageable.
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.state,
    required this.initiallyOpen,
  });

  final CategoryGroup group;
  final LearningState state;
  final bool initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<VocabEntry> entries = group.entries;
    final int learned = entries.where(state.isLearned).length;
    final int due = state.dueEntries(entries).length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyOpen,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(group.icon, color: theme.colorScheme.primary),
        title: Text(
          group.name,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$learned / ${entries.length} gelernt'
                '${due > 0 ? " · $due fällig" : ""}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: entries.isEmpty ? 0 : learned / entries.length,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(group.description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
            ),
          ),
          for (final VocabCategory category in group.categories)
            _CategoryCard(category: category, state: state),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.state});

  final VocabCategory category;
  final LearningState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int learned = state.learnedIn(category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            HomeScreen._push(context, CategoryScreen(category: category)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: category.softColor,
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            category.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$learned / ${category.entries.length}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.progressOf(category),
                        minHeight: 5,
                        backgroundColor: category.softColor,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(category.color),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
