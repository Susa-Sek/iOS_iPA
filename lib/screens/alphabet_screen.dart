import 'package:flutter/material.dart';

import '../data/alphabet_data.dart';
import '../models/vocabulary.dart';
import '../widgets/arabic_text.dart';

/// The 28 letters as a grid; tapping a letter shows its four forms.
class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Das arabische Alphabet')),
      body: Column(
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
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
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
      ),
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
                Text(
                  '${letter.name}  ·  ${letter.transliteration}',
                  style: theme.textTheme.titleLarge,
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
