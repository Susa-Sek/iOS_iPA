import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../state/daily_quests.dart';
import '../state/learning_state.dart';
import '../state/reward_store.dart';
import '../theme/app_theme.dart';

/// Die drei Aufgaben des Tages.
///
/// Das Tagesziel allein sagt jeden Tag dasselbe: „zehn Antworten". Hier steht
/// etwas anderes da als gestern — eine Lektion, ein Thema zum Durchwischen,
/// eine Runde ohne Fehler. Das ist der Unterschied zwischen einer Pflicht und
/// einem Grund, die App aufzumachen.
///
/// Sind alle drei erledigt, gibt es einen **Jokertag**: die Versicherung
/// gegen den einen kranken Tag, der sonst eine Serie von dreißig löscht.
class QuestCard extends StatefulWidget {
  const QuestCard({super.key});

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nach jedem Neuzeichnen prüfen, ob der Tag voll ist. Der Speicher hält
    // fest, dass der Joker für heute schon vergeben wurde — sonst käme bei
    // jeder weiteren Antwort ein neuer.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pruefeJoker());
  }

  Future<void> _pruefeJoker() async {
    if (!mounted) return;
    final LearningState state = LearningScope.of(context);
    final RewardStore rewards = RewardScope.of(context);
    if (!rewards.isLoaded || rewards.freezeEarnedToday) return;
    if (!rewards.allDone(_quests(state))) return;

    await rewards.markFreezeEarned();
    await state.recordQuestDay();
  }

  List<Quest> _quests(LearningState state) => buildQuests(
        day: DateTime.now(),
        dailyGoal: state.dailyGoal,
        hatArabisch: state.hasContent(Subject.arabisch),
        hatWissen: state.hasContent(Subject.wissen),
      );

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final RewardStore rewards = RewardScope.of(context);
    final ThemeData theme = Theme.of(context);

    final List<Quest> quests = _quests(state);
    final int fertig = rewards.doneCount(quests);
    final bool alle = fertig == quests.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.sm, Insets.lg, Insets.xs),
      child: Card(
        child: Padding(
          padding: Insets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.checklist_rtl,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    // Nicht „Heute": So heißt auf der arabischen Startseite
                    // schon die Tageskarte.
                    child: Text('Tagesaufgaben',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Text('$fertig von ${quests.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
              const SizedBox(height: Insets.md),
              for (final Quest quest in quests)
                _QuestZeile(
                  quest: quest,
                  stand: rewards.progressOf(quest.kind),
                ),
              if (alle) ...<Widget>[
                const SizedBox(height: Insets.sm),
                _JokerHinweis(freezes: state.freezes),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestZeile extends StatelessWidget {
  const _QuestZeile({required this.quest, required this.stand});

  final Quest quest;
  final int stand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool fertig = quest.isDone(stand);

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            fertig ? Icons.check_circle : quest.kind.icon,
            size: 20,
            color: fertig
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  quest.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fertig
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                    decoration: fertig ? TextDecoration.lineThrough : null,
                  ),
                ),
                // Nur bei zählenden Aufgaben ein Balken: Bei „eine Lektion"
                // wäre er halb voll oder voll, und das sagt das Häkchen
                // schon.
                if (quest.kind.zaehlt && !fertig) ...<Widget>[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.bar),
                    child: LinearProgressIndicator(
                      value: quest.ratio(stand),
                      minHeight: 4,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            fertig ? '+${quest.xp}' : '${quest.xp}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: fertig
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: fertig ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerHinweis extends StatelessWidget {
  const _JokerHinweis({required this.freezes});

  final int freezes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: Insets.md, vertical: Insets.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: Radii.chipShape,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.ac_unit,
              size: 18, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              freezes > 0
                  ? 'Alles erledigt — $freezes Jokertag'
                      '${freezes == 1 ? '' : 'e'} auf Vorrat.'
                  : 'Alles erledigt.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
