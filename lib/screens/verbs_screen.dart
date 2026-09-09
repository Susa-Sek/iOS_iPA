import 'package:flutter/material.dart';

import '../data/verbs_data.dart';
import '../models/vocabulary.dart';
import '../widgets/arabic_text.dart';
import '../widgets/speak_button.dart';

/// Conjugation tables. Arabic marks the person with a prefix in the present
/// tense, so seeing the whole table once teaches a pattern that repeats
/// across almost every verb.
class VerbsScreen extends StatelessWidget {
  const VerbsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verben beugen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'In der Gegenwart zeigt eine Vorsilbe an, wer handelt: أ für '
              '„ich", تـ für „du", يـ für „er", نـ für „wir". Dieses Muster '
              'wiederholt sich bei fast jedem Verb.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          for (final Verb verb in kVerbs) _VerbCard(verb: verb),
        ],
      ),
    );
  }
}

class _VerbCard extends StatelessWidget {
  const _VerbCard({required this.verb});

  final Verb verb;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          verb.german,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${verb.transliteration} · Wurzel ${verb.root}',
            style: theme.textTheme.bodySmall),
        trailing: ArabicText(verb.past,
            fontSize: 20, color: theme.colorScheme.primary),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const SizedBox(width: 74),
                    Expanded(
                      child: Text('Vergangenheit',
                          style: theme.textTheme.labelSmall),
                    ),
                    Expanded(
                      child: Text('Gegenwart',
                          style: theme.textTheme.labelSmall),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const Divider(height: 12),
                for (final VerbForm form in verb.forms)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 74,
                          child: Text(form.person,
                              style: theme.textTheme.bodySmall),
                        ),
                        Expanded(
                          child: ArabicText(form.past, fontSize: 19),
                        ),
                        Expanded(
                          child: ArabicText(
                            form.present,
                            fontSize: 19,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SpeakButton(text: form.present, size: 18),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    verb.forms
                        .map((VerbForm f) =>
                            '${f.person}: ${f.transliteration}')
                        .join('  ·  '),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
