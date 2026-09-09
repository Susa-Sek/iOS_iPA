import 'package:flutter/material.dart';

import '../data/vocabulary_data.dart';
import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import 'alphabet_screen.dart';
import 'build_word_screen.dart';
import 'category_screen.dart';
import 'flashcard_screen.dart';
import 'matching_screen.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';

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
                  if (value == 'reset') _confirmReset(context, state);
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'reset',
                    child: Text('Fortschritt zurücksetzen'),
                  ),
                ],
              ),
            ],
          ),
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
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Themen',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => _CategoryCard(
                  category: kCategories[index],
                  state: state,
                ),
                childCount: kCategories.length,
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

  Future<void> _confirmReset(BuildContext context, LearningState state) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Fortschritt zurücksetzen?'),
        content: const Text(
          'Alle Lernstände und Quiz-Ergebnisse dieser Sitzung werden '
          'gelöscht.',
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
    if (yes ?? false) state.reset();
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
                      'richtig · Serie: ${state.streak}',
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
