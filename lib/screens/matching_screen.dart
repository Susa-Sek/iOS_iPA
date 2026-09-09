import 'dart:math';

import 'package:flutter/material.dart';

import '../data/vocabulary_data.dart';
import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../widgets/arabic_text.dart';

/// Memory-style pair game: tap a German word, then the Arabic word that
/// belongs to it. Correct pairs disappear, wrong pairs flash red.
class MatchingScreen extends StatefulWidget {
  const MatchingScreen({
    super.key,
    this.entries,
    required this.title,
    this.accent,
    this.accentSoft,
  });

  final List<VocabEntry>? entries;
  final String title;
  final Color? accent;
  final Color? accentSoft;

  /// Pairs shown per round.
  static const int pairsPerRound = 6;

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final Random _random = Random();

  late List<VocabEntry> _pool;
  late List<VocabEntry> _round;
  late List<VocabEntry> _germanColumn;
  late List<VocabEntry> _arabicColumn;

  final Set<String> _solved = <String>{};
  VocabEntry? _pickedGerman;
  VocabEntry? _pickedArabic;
  bool _wrong = false;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _pool = List<VocabEntry>.of(widget.entries ?? kAllEntries);
    _round = <VocabEntry>[];
    WidgetsBinding.instance.addPostFrameCallback((_) => _deal());
  }

  void _deal() {
    final LearningState state = LearningScope.of(context);
    final List<VocabEntry> ordered = state.trainingOrder(_pool, random: _random);
    final int count = min(MatchingScreen.pairsPerRound, ordered.length);
    setState(() {
      _round = ordered.take(count).toList();
      _germanColumn = List<VocabEntry>.of(_round)..shuffle(_random);
      _arabicColumn = List<VocabEntry>.of(_round)..shuffle(_random);
      _solved.clear();
      _pickedGerman = null;
      _pickedArabic = null;
      _mistakes = 0;
      _wrong = false;
    });
  }

  void _pick({VocabEntry? german, VocabEntry? arabic}) {
    if (_wrong) return;
    setState(() {
      if (german != null) _pickedGerman = german;
      if (arabic != null) _pickedArabic = arabic;
    });
    _evaluate();
  }

  void _evaluate() {
    final VocabEntry? g = _pickedGerman;
    final VocabEntry? a = _pickedArabic;
    if (g == null || a == null) return;

    final LearningState state = LearningScope.of(context);
    final bool hit = g.id == a.id;
    state.recordAnswer(correct: hit);

    if (hit) {
      state.promote(g);
      setState(() {
        _solved.add(g.id);
        _pickedGerman = null;
        _pickedArabic = null;
      });
    } else {
      state.demote(g);
      setState(() {
        _wrong = true;
        _mistakes++;
      });
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _wrong = false;
          _pickedGerman = null;
          _pickedArabic = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = widget.accent ?? theme.colorScheme.primary;
    final Color accentSoft =
        widget.accentSoft ?? theme.colorScheme.primaryContainer;
    final bool done = _round.isNotEmpty && _solved.length == _round.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Zuordnen · ${widget.title}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Neue Runde',
            icon: const Icon(Icons.refresh),
            onPressed: _deal,
          ),
        ],
      ),
      body: _round.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : done
              ? _Done(mistakes: _mistakes, accent: accent, onAgain: _deal)
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Tippe ein deutsches Wort und dann seine arabische '
                        'Entsprechung.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: ListView(
                                children: <Widget>[
                                  for (final VocabEntry e in _germanColumn)
                                    _Chip(
                                      label: e.german,
                                      arabic: false,
                                      solved: _solved.contains(e.id),
                                      selected: _pickedGerman?.id == e.id,
                                      wrong: _wrong && _pickedGerman?.id == e.id,
                                      accent: accent,
                                      accentSoft: accentSoft,
                                      onTap: () => _pick(german: e),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ListView(
                                children: <Widget>[
                                  for (final VocabEntry e in _arabicColumn)
                                    _Chip(
                                      label: e.arabic,
                                      arabic: true,
                                      solved: _solved.contains(e.id),
                                      selected: _pickedArabic?.id == e.id,
                                      wrong: _wrong && _pickedArabic?.id == e.id,
                                      accent: accent,
                                      accentSoft: accentSoft,
                                      onTap: () => _pick(arabic: e),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('${_solved.length} / ${_round.length} Paare'),
                    ],
                  ),
                ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.arabic,
    required this.solved,
    required this.selected,
    required this.wrong,
    required this.accent,
    required this.accentSoft,
    required this.onTap,
  });

  final String label;
  final bool arabic;
  final bool solved;
  final bool selected;
  final bool wrong;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background = wrong
        ? theme.colorScheme.errorContainer
        : selected
            ? accentSoft
            : theme.cardColor;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: solved ? 0.25 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: solved ? null : onTap,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: arabic
                  ? ArabicText(
                      label,
                      fontSize: 22,
                      textAlign: TextAlign.center,
                      color: selected ? accent : null,
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({
    required this.mistakes,
    required this.accent,
    required this.onAgain,
  });

  final int mistakes;
  final Color accent;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.celebration_outlined, size: 64, color: accent),
          const SizedBox(height: 16),
          Text('Alle Paare gefunden!', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(mistakes == 0
              ? 'Ohne einen einzigen Fehler.'
              : '$mistakes Fehlversuche'),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Neue Runde'),
            onPressed: onAgain,
          ),
        ],
      ),
    );
  }
}
