import 'dart:math';

import 'package:flutter/material.dart';

import '../data/vocabulary_data.dart';
import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../widgets/arabic_text.dart';

/// "Wort bauen": the German word is given, the Arabic word has to be
/// assembled from its shuffled letters.
class BuildWordScreen extends StatefulWidget {
  const BuildWordScreen({
    super.key,
    this.entries,
    required this.title,
    this.accent,
  });

  final List<VocabEntry>? entries;
  final String title;
  final Color? accent;

  static const int wordsPerRound = 8;

  /// Only short single words can be assembled letter by letter.
  static bool isSuitable(VocabEntry entry) {
    final String word = entry.arabic;
    if (word.contains(' ')) return false;
    final int length = word.runes.length;
    return length >= 3 && length <= 7;
  }

  @override
  State<BuildWordScreen> createState() => _BuildWordScreenState();
}

class _BuildWordScreenState extends State<BuildWordScreen> {
  final Random _random = Random();

  late List<VocabEntry> _round;
  final List<int> _picked = <int>[];
  List<String> _tiles = <String>[];
  int _index = 0;
  int _solved = 0;
  bool? _result;

  @override
  void initState() {
    super.initState();
    final List<VocabEntry> pool = (widget.entries ?? kAllEntries)
        .where(BuildWordScreen.isSuitable)
        .toList()
      ..shuffle(_random);
    _round = pool.take(BuildWordScreen.wordsPerRound).toList();
    if (_round.isNotEmpty) _deal();
  }

  void _deal() {
    _tiles = _round[_index].arabic.runes
        .map((int r) => String.fromCharCode(r))
        .toList()
      ..shuffle(_random);
    _picked.clear();
    _result = null;
  }

  String get _assembled =>
      _picked.map((int i) => _tiles[i]).join();

  void _check() {
    final VocabEntry entry = _round[_index];
    final bool correct = _assembled == entry.arabic;
    final LearningState state = LearningScope.of(context);
    state.recordAnswer(correct: correct);
    if (correct) {
      state.promote(entry);
      _solved++;
    } else {
      state.demote(entry);
    }
    setState(() => _result = correct);
  }

  void _next() => setState(() {
        _index++;
        if (_index < _round.length) _deal();
      });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = widget.accent ?? theme.colorScheme.primary;

    if (_round.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wort bauen')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'In diesem Thema gibt es keine kurzen Einzelwörter zum Bauen.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_index >= _round.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wort bauen')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.construction_outlined, size: 64, color: accent),
              const SizedBox(height: 16),
              Text('$_solved von ${_round.length} Wörtern gebaut',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('Zurück'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final VocabEntry entry = _round[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text('Wort bauen · ${widget.title}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _index / _round.length,
            minHeight: 4,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Wort ${_index + 1} von ${_round.length}',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: <Widget>[
                    Text(entry.german,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(entry.transliteration,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _result == null
                      ? theme.dividerColor
                      : _result!
                          ? const Color(0xFF2E7D32)
                          : theme.colorScheme.error,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _picked.isEmpty
                  ? Text('Tippe die Buchstaben an',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor))
                  : ArabicText(_assembled, fontSize: 34, color: accent),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _picked.isEmpty || _result != null
                    ? null
                    : () => setState(() {
                        _picked.removeLast();
                      }),
                icon: const Icon(Icons.backspace_outlined),
                label: const Text('Zurück'),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (int i = 0; i < _tiles.length; i++)
                      _LetterTile(
                        letter: _tiles[i],
                        used: _picked.contains(i),
                        accent: accent,
                        onTap: _result != null
                            ? null
                            : () => setState(() => _picked.add(i)),
                      ),
                  ],
                ),
              ),
            ),
            if (_result == false)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Richtig wäre: ', style: theme.textTheme.bodyMedium),
                    ArabicText(entry.arabic, fontSize: 24),
                  ],
                ),
              ),
            if (_result == null)
              FilledButton(
                onPressed:
                    _picked.length == _tiles.length ? _check : null,
                child: const Text('Prüfen'),
              )
            else
              FilledButton(
                onPressed: _next,
                child: Text(_index == _round.length - 1
                    ? 'Ergebnis ansehen'
                    : 'Nächstes Wort'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.used,
    required this.accent,
    required this.onTap,
  });

  final String letter;
  final bool used;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Opacity(
      opacity: used ? 0.25 : 1,
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: used ? null : onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Center(
              child: ArabicText(
                letter,
                fontSize: 28,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
