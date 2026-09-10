import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../theme/app_theme.dart';

/// Eine Wissenskarte in einer Liste.
///
/// Der Unterschied zu `WordTile` ist der Punkt der ganzen Umstellung: Dort
/// steht ein Wort mit Lautschrift, Lernstufe und Häkchen — bei einer
/// Wissenskarte war die Lautschriftzeile immer leer, die Lernstufe sagte
/// nichts, und **die Antwort stand nirgends**. Hier steht sie.
class KnowledgeTile extends StatefulWidget {
  const KnowledgeTile({super.key, required this.entry, this.accent});

  final VocabEntry entry;
  final Color? accent;

  @override
  State<KnowledgeTile> createState() => _KnowledgeTileState();
}

class _KnowledgeTileState extends State<KnowledgeTile> {
  bool _offen = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final VocabEntry entry = widget.entry;
    final Color akzent = widget.accent ?? theme.colorScheme.primary;
    final bool frage = entry.question != null;

    return InkWell(
      // Die Erklärung wird auf Wunsch aufgeklappt — sie ist der Grund, warum
      // die Karte mehr ist als ein Faktenschnipsel.
      onTap: entry.explanation == null
          ? null
          : () => setState(() => _offen = !_offen),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg, vertical: Insets.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2, right: Insets.md),
              child: Icon(
                frage ? Icons.help_outline : Icons.lightbulb_outline,
                size: 18,
                color: akzent,
                semanticLabel: frage ? 'Frage' : 'Begriff',
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(entry.prompt, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    entry.answer,
                    style: theme.textTheme.bodyMedium?.copyWith(color: akzent),
                  ),
                  if (entry.explanation case final String erklaerung) ...<Widget>[
                    const SizedBox(height: 6),
                    AnimatedCrossFade(
                      duration: Motion.fast,
                      crossFadeState: _offen
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Text(
                        erklaerung,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      secondChild: Text(
                        erklaerung,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
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
