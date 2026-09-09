import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import 'arabic_text.dart';
import 'level_dots.dart';

/// One vocabulary row: German on the left, Arabic on the right, the
/// transliteration underneath and a checkbox for "das kann ich schon".
class WordTile extends StatelessWidget {
  const WordTile({
    super.key,
    required this.entry,
    this.accent,
    this.accentSoft,
  });

  final VocabEntry entry;
  final Color? accent;
  final Color? accentSoft;

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final bool learned = state.isLearned(entry);
    final int box = state.boxOf(entry);
    final ThemeData theme = Theme.of(context);
    final Color color = accent ?? theme.colorScheme.primary;

    return InkWell(
      onTap: () => state.toggleLearned(entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  learned ? Icons.check_circle : Icons.circle_outlined,
                  color: learned ? color : theme.disabledColor,
                  semanticLabel: learned ? 'Gelernt' : 'Noch nicht gelernt',
                ),
                const SizedBox(height: 6),
                LevelDots(box: box, color: color, softColor: accentSoft),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.german,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.transliteration,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: ArabicText(
                entry.arabic,
                fontSize: 22,
                color: color,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
