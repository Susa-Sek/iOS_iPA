import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../screens/quiz_screen.dart';
import '../state/daily_card_store.dart';
import '../theme/app_theme.dart';

/// Was der Tag gebracht hat — und ein Griff, es gleich zu lernen.
///
/// **Warum das auf die Startseite gehört.** Der Tagesstoff lag bisher im
/// Bereich „Heute", den man selten aufschlägt. Jetzt kommt er von selbst in
/// den Bestand — aber wenn man ihn nirgends sieht, verschwindet er lautlos
/// in der Wiederholung. Hier steht er einen Tag lang, mit einer Runde von
/// zwei Fragen dahinter: dreißig Sekunden, jeden Tag etwas anderes.
class DailyFindCard extends StatelessWidget {
  const DailyFindCard({super.key});

  @override
  Widget build(BuildContext context) {
    final DailyCardStore funde = DailyCardScope.of(context);
    final List<VocabEntry> neu = funde.latest;
    if (neu.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.sm, Insets.lg, Insets.xs),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => QuizScreen(
                entries: neu,
                title: 'Neu von heute',
                count: neu.length,
              ),
            ),
          ),
          child: Padding(
            padding: Insets.card,
            child: Row(
              children: <Widget>[
                Icon(Icons.auto_awesome,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text('Neu von heute',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: Insets.sm),
                          Text(
                            neu.length == 1 ? '1 Karte' : '${neu.length} Karten',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // Die Begriffe selbst, nicht „2 neue Inhalte": Man
                        // soll sehen, worum es geht, bevor man tippt.
                        neu.map(_kurz).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
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
      ),
    );
  }

  /// Bei einer Jahresfrage steht der ganze Satz im Begriff — hier genügt der
  /// Anfang.
  static String _kurz(VocabEntry entry) {
    const int max = 38;
    final String text = entry.german;
    if (text.length <= max) return text;
    return '${text.substring(0, max).trimRight()}…';
  }
}
