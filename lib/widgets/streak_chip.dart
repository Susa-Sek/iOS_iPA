import 'package:flutter/material.dart';

import '../screens/app_shell.dart';
import '../state/learning_state.dart';
import '../theme/app_theme.dart';

/// Serie und Punkte in der Kopfzeile.
///
/// **Warum das hier steht und nicht nur unter „Erfolge".** Wer etwas
/// gewinnt, muss es sehen, und zwar dort, wo er ohnehin hinschaut. Serie und
/// Punkte lagen bisher einen Bereich weiter; man lernte wochenlang, ohne je
/// zu bemerken, dass eine Zahl mitläuft.
///
/// Die Flamme brennt erst, wenn das Tagesziel gefallen ist. Vorher ist sie
/// grau — der Unterschied zwischen „heute schon" und „heute noch nicht",
/// ohne dass man ihn lesen muss.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final ThemeData theme = Theme.of(context);
    final bool heuteSchon = state.goalReached;
    final int serie = state.dayStreak;

    final Color flamme = heuteSchon
        ? const Color(0xFFE8590C)
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: serie > 0
          ? 'Serie $serie Tage, ${state.xp} Punkte. Führt zu den Erfolgen.'
          : '${state.xp} Punkte. Führt zu den Erfolgen.',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: Radii.chipShape,
          child: InkWell(
            borderRadius: Radii.chipShape,
            onTap: () => AppTabs.open(context, AppTabs.erfolge),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md, vertical: Insets.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    heuteSchon
                        ? Icons.local_fire_department
                        : Icons.local_fire_department_outlined,
                    size: 18,
                    color: flamme,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$serie',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: flamme,
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Container(
                    width: 1,
                    height: 14,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: Insets.sm),
                  Icon(Icons.bolt,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 2),
                  Text(
                    _kurz(state.xp),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
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

  /// Ab tausend wird gekürzt: „12.480" sprengt die Kopfzeile, „12,4k" nicht.
  static String _kurz(int punkte) {
    if (punkte < 1000) return '$punkte';
    final double k = punkte / 1000;
    return k >= 10
        ? '${k.round()}k'
        : '${k.toStringAsFixed(1).replaceAll('.', ',')}k';
  }
}
