import 'package:flutter/material.dart';

import '../state/learning_state.dart';
import '../state/session_plan.dart';
import '../theme/app_theme.dart';

/// „Lernen nach Maß" — Blockgröße und Kurzrunde einstellen.
///
/// An einer Stelle und nicht in zwei Menüs: Beides beantwortet dieselbe
/// Frage — wie viel auf einmal, und woraus.
class LearningSettingsSheet extends StatelessWidget {
  const LearningSettingsSheet({super.key});

  /// Öffnet das Blatt.
  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => const LearningSettingsSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final ThemeData theme = Theme.of(context);
    final Set<ExerciseKind> gewaehlt = state.sessionKinds;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            Insets.lg, 0, Insets.lg, Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Lernen nach Maß', style: theme.textTheme.titleLarge),
            const SizedBox(height: Insets.xl),

            // ---- Blockgröße ------------------------------------------
            Text('Wörter je Block',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Insets.xs),
            Text(
              'So viele Wörter werden geübt, bis sie sitzen. Erst dann '
              'rückt der Block weiter.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.sm,
              children: <Widget>[
                for (final int groesse in <int>[5, 10, 15, 20, 30])
                  ChoiceChip(
                    label: Text('$groesse'),
                    selected: state.blockSize == groesse,
                    onSelected: (_) => state.setBlockSize(groesse),
                  ),
              ],
            ),

            const SizedBox(height: Insets.xl),
            const Divider(),
            const SizedBox(height: Insets.md),

            // ---- Kurzrunde -------------------------------------------
            Text('Kurzrunde', style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Insets.xs),
            Text(
              'Welche Übungsarten vorkommen dürfen. Eine bleibt immer an — '
              'eine Kurzrunde ohne Übung wäre ein Knopf ins Leere.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.sm),
            for (final ExerciseKind kind in ExerciseKind.values)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: gewaehlt.contains(kind),
                title: Text(kind.label),
                // Die letzte Art lässt sich nicht abwählen.
                onChanged: gewaehlt.length == 1 && gewaehlt.contains(kind)
                    ? null
                    : (bool? an) {
                        final Set<ExerciseKind> neu =
                            Set<ExerciseKind>.of(gewaehlt);
                        if (an == true) {
                          neu.add(kind);
                        } else {
                          neu.remove(kind);
                        }
                        state.setSessionKinds(neu);
                      },
              ),

            const SizedBox(height: Insets.md),
            Text('Blöcke je Runde',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.sm,
              children: <Widget>[
                for (final int anzahl in <int>[2, 3, 4, 5])
                  ChoiceChip(
                    label: Text('$anzahl'),
                    selected: state.sessionBlocks == anzahl,
                    onSelected: (_) => state.setSessionBlocks(anzahl),
                  ),
              ],
            ),

            const SizedBox(height: Insets.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fertig'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
