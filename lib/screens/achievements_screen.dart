import 'package:flutter/material.dart';

import '../data/achievements_data.dart';
import '../models/achievement.dart';
import '../state/learning_state.dart';

/// Level, Punkte und die Abzeichen — was schon geschafft ist und was als
/// Nächstes drankommt.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final ThemeData theme = Theme.of(context);
    final AchievementStats stats = state.achievementStats;

    final List<Achievement> unlocked =
        kAchievements.where((Achievement a) => a.isUnlocked(stats)).toList();
    final List<Achievement> open =
        kAchievements.where((Achievement a) => !a.isUnlocked(stats)).toList()
          ..sort((Achievement a, Achievement b) =>
              b.ratio(stats).compareTo(a.ratio(stats)));

    return Scaffold(
      appBar: AppBar(title: const Text('Erfolge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          _LevelCard(state: state),
          const SizedBox(height: 16),
          _Stats(state: state, stats: stats),
          const SizedBox(height: 20),
          Text(
            'Abzeichen  ·  ${unlocked.length} von ${kAchievements.length}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final Achievement a in unlocked)
            _AchievementTile(achievement: a, stats: stats, unlocked: true),
          if (open.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text('Als Nächstes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final Achievement a in open)
              _AchievementTile(achievement: a, stats: stats, unlocked: false),
          ],
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.state});

  final LearningState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int toNext = state.xpForNextLevel - state.xp;

    return Card(
      color: theme.colorScheme.primaryContainer,
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
                      value: state.levelProgress,
                      strokeWidth: 7,
                      backgroundColor: theme.colorScheme.surface,
                    ),
                  ),
                  Text('${state.level}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Level ${state.level}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    '${state.xp} Punkte · noch $toNext bis Level '
                    '${state.level + 1}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.state, required this.stats});

  final LearningState state;
  final AchievementStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _StatTile(
          value: '${stats.dayStreak}',
          label: stats.dayStreak == 1 ? 'Tag Serie' : 'Tage Serie',
          icon: Icons.local_fire_department_outlined,
        ),
        _StatTile(
          value: '${stats.learnedWords}',
          label: 'Wörter sitzen',
          icon: Icons.check_circle_outline,
        ),
        _StatTile(
          value: '${state.goalDays}',
          label: 'Ziele erreicht',
          icon: Icons.flag_outlined,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.stats,
    required this.unlocked,
  });

  final Achievement achievement;
  final AchievementStats stats;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int have = achievement.progress(stats);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: unlocked
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                unlocked ? achievement.icon : Icons.lock_outline,
                color: unlocked
                    ? theme.colorScheme.primary
                    : theme.disabledColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    achievement.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: unlocked ? null : theme.disabledColor,
                    ),
                  ),
                  Text(achievement.description,
                      style: theme.textTheme.bodySmall),
                  if (!unlocked) ...<Widget>[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.ratio(stats),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$have von ${achievement.target}',
                        style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
            if (unlocked)
              Icon(Icons.verified, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
