import 'package:flutter/material.dart';

import '../data/quran_data.dart';
import '../models/quran.dart';
import '../widgets/arabic_text.dart';
import '../widgets/speak_button.dart';

/// Shows how many words grow out of one three-letter root.
class RootsScreen extends StatelessWidget {
  const RootsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Wurzeln')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Text(
            'Fast jedes arabische Wort geht auf drei Konsonanten zurück. Die '
            'Wurzel trägt die Grundbedeutung, das Muster darum herum macht '
            'daraus ein Verb, einen Ort, eine Person oder eine Eigenschaft.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final ArabicRoot root in kRoots)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ArabicText(
                          root.letters,
                          fontSize: 24,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            root.meaning,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    for (final QuranWord word in root.derivations)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 110,
                              child: ArabicText(word.arabic, fontSize: 20),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(word.german,
                                      style: theme.textTheme.bodyMedium),
                                  Text(
                                    word.transliteration,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                            fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                            SpeakButton(text: word.arabic, size: 18),
                          ],
                        ),
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
