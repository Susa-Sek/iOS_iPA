import 'package:flutter/material.dart';

import '../data/quran_data.dart';
import '../data/quran_vocab.dart';
import '../models/quran.dart';
import '../state/learning_state.dart';
import '../widgets/arabic_text.dart';
import 'category_screen.dart';
import 'roots_screen.dart';
import 'sura_screen.dart';

/// Entry point for the Quran part: the short suras, the most frequent words
/// and the root system.
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LearningState state = LearningScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Quran-Sprache')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Text(
            'Die Sprache des Quran ist klassisches Hocharabisch. Wer die '
            'häufigsten Wörter und das Wurzelsystem kennt, versteht große '
            'Teile des Textes im Original.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _Tile(
            icon: Icons.format_list_numbered,
            title: 'Häufigste Wörter',
            subtitle: '${kQuranWords.entries.length} Wortformen · '
                'rund 38 % des gesamten Textes · '
                '${state.learnedIn(kQuranWords)} gelernt',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CategoryScreen(category: kQuranWords),
              ),
            ),
          ),
          _Tile(
            icon: Icons.account_tree_outlined,
            title: 'Wurzeln',
            subtitle: '${kRoots.length} Wurzeln und die Wörter, '
                'die aus ihnen entstehen',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RootsScreen()),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kurze Suren, Wort für Wort',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final QuranSura sura in kSuras)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${sura.number}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(sura.name),
                subtitle: Text('${sura.meaning} · ${sura.verseCount} Verse'),
                trailing: ArabicText(sura.arabicName, fontSize: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SuraScreen(sura: sura),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Zur Quelle',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Der arabische Text stammt unverändert aus der Ausgabe '
                    '"quran-simple" des Tanzil-Projekts. Die deutschen Zeilen '
                    'sind eine Verständnishilfe zum Sprachenlernen und '
                    'ersetzen keine anerkannte Übersetzung.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
