import 'package:flutter/material.dart';

import '../data/quran_data.dart';
import '../models/quran.dart';
import '../widgets/arabic_text.dart';
import '../widgets/speak_button.dart';

/// A sura, verse by verse: the Arabic line, a German rendering, and — when
/// the learner asks for it — every single word with its meaning.
class SuraScreen extends StatefulWidget {
  const SuraScreen({super.key, required this.sura});

  final QuranSura sura;

  @override
  State<SuraScreen> createState() => _SuraScreenState();
}

class _SuraScreenState extends State<SuraScreen> {
  bool _wordByWord = true;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuranSura sura = widget.sura;

    return Scaffold(
      appBar: AppBar(
        title: Text(sura.name),
        actions: <Widget>[
          IconButton(
            tooltip: _wordByWord
                ? 'Wort für Wort ausblenden'
                : 'Wort für Wort anzeigen',
            icon: Icon(_wordByWord ? Icons.grid_view : Icons.notes),
            onPressed: () => setState(() => _wordByWord = !_wordByWord),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                ArabicText(sura.arabicName,
                    fontSize: 26, color: theme.colorScheme.primary),
                Text('${sura.name} · ${sura.meaning}',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(sura.about,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(height: 28),
          if (sura.opensWithBasmala) ...<Widget>[
            _VerseCard(
              verse: kBasmala,
              wordByWord: _wordByWord,
              label: 'Basmala',
            ),
            const SizedBox(height: 6),
          ],
          for (final QuranVerse verse in sura.verses)
            _VerseCard(verse: verse, wordByWord: _wordByWord),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.wordByWord,
    this.label,
  });

  final QuranVerse verse;
  final bool wordByWord;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  label ?? 'Vers ${verse.number}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.hintColor),
                ),
                const Spacer(),
                SpeakButton(text: verse.arabic, size: 20),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ArabicText(
                verse.arabic,
                fontSize: 26,
                color: theme.colorScheme.primary,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(verse.german, style: theme.textTheme.bodyMedium),
            ),
            if (wordByWord) ...<Widget>[
              const SizedBox(height: 12),
              // Rechts beginnend, damit die Reihenfolge der Schrift folgt.
              Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final QuranWord word in verse.words)
                      _WordChip(word: word),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word});

  final QuranWord word;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ArabicText(word.arabic, fontSize: 22),
          const SizedBox(height: 2),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: <Widget>[
                Text(
                  word.transliteration,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
                Text(word.german, style: theme.textTheme.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
