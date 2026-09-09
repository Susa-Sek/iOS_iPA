import 'dart:math';

import 'package:flutter/material.dart';

import '../data/vocabulary_data.dart';
import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../widgets/arabic_text.dart';
import '../widgets/level_dots.dart';

/// Flashcards with a flip: German on the front, Arabic and the
/// transliteration on the back — or the other way round.
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({
    super.key,
    this.entries,
    required this.title,
    this.accent,
    this.accentSoft,
  });

  /// The words to train, or `null` for the whole vocabulary.
  final List<VocabEntry>? entries;
  final String title;
  final Color? accent;
  final Color? accentSoft;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final Random _random = Random();

  List<VocabEntry> _cards = <VocabEntry>[];
  bool _dealt = false;
  bool _arabicFirst = false;
  bool _revealed = false;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dealt) return;
    _dealt = true;
    _shuffle();
  }

  void _shuffle() {
    final List<VocabEntry> pool =
        List<VocabEntry>.of(widget.entries ?? kAllEntries);
    _cards = LearningScope.of(context).trainingOrder(pool, random: _random);
    _index = 0;
    _revealed = false;
  }

  void _rate({required bool known}) {
    final LearningState state = LearningScope.of(context);
    if (known) {
      state.promote(_cards[_index]);
    } else {
      state.demote(_cards[_index]);
    }
    setState(() {
      _revealed = false;
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = widget.accent ?? theme.colorScheme.primary;

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_index >= _cards.length) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.emoji_events_outlined, size: 64, color: accent),
              const SizedBox(height: 16),
              Text('Stapel geschafft!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('${_cards.length} Karten durchgearbeitet'),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Nochmal mischen'),
                onPressed: () => setState(_shuffle),
              ),
            ],
          ),
        ),
      );
    }

    final VocabEntry card = _cards[_index];
    final LearningState state = LearningScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Karteikarten · ${widget.title}'),
        actions: <Widget>[
          IconButton(
            tooltip: _arabicFirst
                ? 'Vorderseite: Arabisch'
                : 'Vorderseite: Deutsch',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => setState(() {
              _arabicFirst = !_arabicFirst;
              _revealed = false;
            }),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _index / _cards.length,
            minHeight: 4,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Karte ${_index + 1} von ${_cards.length}',
                    style: theme.textTheme.labelLarge),
                LevelDots(
                  box: state.boxOf(card),
                  color: accent,
                  softColor: widget.accentSoft,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: Card(
                  elevation: 2,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_arabicFirst)
                            ArabicText(
                              card.arabic,
                              fontSize: 40,
                              color: accent,
                              textAlign: TextAlign.center,
                            )
                          else
                            Text(
                              card.german,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          const SizedBox(height: 28),
                          if (_revealed) ...<Widget>[
                            if (_arabicFirst)
                              Text(
                                card.german,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              )
                            else
                              ArabicText(
                                card.arabic,
                                fontSize: 40,
                                color: accent,
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 12),
                            Text(
                              card.transliteration,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ] else
                            Text(
                              'Zum Aufdecken tippen',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.hintColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nochmal üben'),
                    onPressed: () => _rate(known: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Kann ich'),
                    onPressed: () => _rate(known: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
