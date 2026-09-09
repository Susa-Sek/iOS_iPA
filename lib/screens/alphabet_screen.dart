import 'package:flutter/material.dart';

import '../data/alphabet_data.dart';
import '../models/vocabulary.dart';
import '../widgets/arabic_text.dart';
import '../widgets/speak_button.dart';

/// Two references in one screen: the 28 letters, and the Tashkīl marks that
/// make a written word pronounceable.
class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alphabet & Zeichen'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Buchstaben'),
              Tab(text: 'Zeichen'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _LettersTab(),
            _DiacriticsTab(),
          ],
        ),
      ),
    );
  }
}

class _LettersTab extends StatelessWidget {
  const _LettersTab();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            'Arabisch wird von rechts nach links geschrieben. Die meisten '
            'Buchstaben ändern ihre Form, je nachdem ob sie am Anfang, in '
            'der Mitte oder am Ende eines Wortes stehen.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 118,
            ),
            itemCount: kAlphabet.length,
            itemBuilder: (BuildContext context, int index) {
              final ArabicLetter letter = kAlphabet[index];
              return Card(
                margin: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showLetter(context, letter),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ArabicText(
                        letter.isolated,
                        fontSize: 34,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          letter.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          letter.transliteration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLetter(BuildContext context, ArabicLetter letter) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ArabicText(
                  letter.isolated,
                  fontSize: 64,
                  color: theme.colorScheme.primary,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        '${letter.name}  ·  ${letter.transliteration}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    SpeakButton(text: letter.isolated),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  letter.hint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 24,
                  runSpacing: 16,
                  children: <Widget>[
                    _Form(label: 'allein', form: letter.isolated),
                    _Form(label: 'Anfang', form: letter.initial),
                    _Form(label: 'Mitte', form: letter.medial),
                    _Form(label: 'Ende', form: letter.finalForm),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiacriticsTab extends StatelessWidget {
  const _DiacriticsTab();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: kDiacritics.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              'Die arabische Schrift notiert vor allem Konsonanten. Die '
              'kurzen Vokale kommen als kleine Zeichen dazu — erst mit ihnen '
              'steht fest, wie ein Wort klingt. In dieser App sind deshalb '
              'alle Vokabeln vollständig gesetzt.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        final ArabicDiacritic mark = kDiacritics[index - 1];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 56,
                  child: Center(
                    child: ArabicText(
                      mark.symbol,
                      fontSize: 34,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              mark.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          ArabicText(mark.arabicName, fontSize: 18),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          ArabicText(
                            mark.example,
                            fontSize: 26,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              '= ${mark.sound}',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                          SpeakButton(text: mark.example, size: 20),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(mark.hint, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.label, required this.form});

  final String label;
  final String form;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ArabicText(form, fontSize: 30),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
