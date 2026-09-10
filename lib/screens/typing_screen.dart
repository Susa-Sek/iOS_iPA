import 'dart:math';

import 'package:flutter/material.dart' hide Feedback;

import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../state/typing_check.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/arabic_text.dart';
import '../widgets/speak_button.dart';

/// Tippen: die Antwort selbst schreiben, statt sie aus vieren zu wählen.
///
/// Die härteste der Übungen — bei vier Antworten erkennt man oft wieder, was
/// man nicht abrufen könnte. Getippt wird immer die deutsche Seite: Ein
/// arabisches Wort lässt sich auf einer deutschen Tastatur nicht eingeben.
class TypingScreen extends StatefulWidget {
  const TypingScreen({
    super.key,
    this.entries,
    required this.title,
  });

  final List<VocabEntry>? entries;
  final String title;

  /// Wie viele Wörter eine Runde hat.
  static const int wordsPerRound = 10;

  static bool isSuitable(VocabEntry entry) => isTypeable(entry);

  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> {
  final Random _random = Random();
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<VocabEntry> _round = <VocabEntry>[];
  bool _dealt = false;
  int _index = 0;
  int _solved = 0;
  TypingResult? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dealt) return;
    _dealt = true;
    _deal();
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _deal() {
    final LearningState state = LearningScope.of(context);
    final List<VocabEntry> pool = (widget.entries ?? state.content.entries)
        .where(TypingScreen.isSuitable)
        .toList();
    _round = state
        .trainingOrder(pool, random: _random)
        .take(TypingScreen.wordsPerRound)
        .toList();
    _index = 0;
    _solved = 0;
    _result = null;
    _input.clear();
  }

  void _check() {
    if (_result != null) return;
    final VocabEntry entry = _round[_index];
    final TypingResult result = checkTyped(_input.text, entry);
    final LearningState state = LearningScope.of(context);

    AnswerFeedback.tap(correct: result.isCorrect);
    if (result.isCorrect) {
      state.promote(entry);
      _solved++;
    } else {
      state.demote(entry);
    }
    state.recordAnswer(correct: result.isCorrect);
    setState(() => _result = result);
  }

  void _next() {
    setState(() {
      _index++;
      _result = null;
      _input.clear();
    });
    if (_index < _round.length) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: _round.isEmpty
            ? const _NothingToType()
            : _index >= _round.length
                ? _Summary(
                    solved: _solved,
                    total: _round.length,
                    onAgain: () => setState(_deal),
                  )
                : _question(theme),
      ),
    );
  }

  Widget _question(ThemeData theme) {
    final VocabEntry entry = _round[_index];
    final TypingResult? result = _result;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.lg, Insets.lg, Insets.xxl),
      children: <Widget>[
        LinearProgressIndicator(
          value: _index / _round.length,
          borderRadius: Radii.chipShape,
        ),
        const SizedBox(height: Insets.md),
        Text('Wort ${_index + 1} von ${_round.length}',
            style: theme.textTheme.labelLarge),
        const SizedBox(height: Insets.lg),
        Card(
          child: Padding(
            padding: Insets.card,
            child: Column(
              children: <Widget>[
                if (entry.isLanguage) ...<Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: ArabicText(
                          typedPrompt(entry),
                          fontSize: 34,
                          color: theme.colorScheme.primary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SpeakButton(
                        text: typedPrompt(entry),
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  if (entry.transliteration.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Insets.xs),
                    Text(entry.transliteration,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ] else
                  Text(
                    typedPrompt(entry),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        TextField(
          controller: _input,
          focusNode: _focus,
          autofocus: true,
          enabled: result == null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => result == null ? _check() : _next(),
          decoration: InputDecoration(
            labelText: entry.isLanguage ? 'Deutsch' : 'Antwort',
            border: const OutlineInputBorder(borderRadius: Radii.chipShape),
            suffixIcon: result == null
                ? null
                : Icon(
                    result.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: result.isCorrect
                        ? Feedback.right(context)
                        : theme.colorScheme.error,
                  ),
          ),
        ),
        const SizedBox(height: Insets.md),
        if (result == null)
          FilledButton(onPressed: _check, child: const Text('Prüfen'))
        else ...<Widget>[
          _Verdict(result: result, entry: entry),
          const SizedBox(height: Insets.md),
          FilledButton(
            onPressed: _next,
            child: Text(_index == _round.length - 1
                ? 'Ergebnis ansehen'
                : 'Weiter'),
          ),
        ],
      ],
    );
  }
}

/// Die Rückmeldung nach dem Prüfen.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.result, required this.entry});

  final TypingResult result;
  final VocabEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color farbe = result.isCorrect
        ? Feedback.right(context)
        : theme.colorScheme.error;

    final String kopf = switch (result.verdict) {
      TypingVerdict.exact => 'Richtig.',
      TypingVerdict.almost => 'Fast — so wird es geschrieben:',
      TypingVerdict.wrong => 'Richtig wäre gewesen:',
    };

    return Container(
      width: double.infinity,
      padding: Insets.card,
      decoration: BoxDecoration(
        color: farbe.withValues(alpha: 0.10),
        borderRadius: Radii.cardShape,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(kopf,
              style: theme.textTheme.labelLarge?.copyWith(color: farbe)),
          if (result.verdict != TypingVerdict.exact) ...<Widget>[
            const SizedBox(height: Insets.xs),
            Text(result.answer, style: theme.textTheme.titleMedium),
          ],
          if (entry.explanation case final String erklaerung) ...<Widget>[
            const SizedBox(height: Insets.sm),
            Text(erklaerung, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.solved,
    required this.total,
    required this.onAgain,
  });

  final int solved;
  final int total;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: Insets.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.keyboard_alt_outlined,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: Insets.lg),
            Text('$solved von $total getroffen',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: Insets.sm),
            Text(
              solved == total
                  ? 'Alles aus dem Kopf — das ist mehr wert als Ankreuzen.'
                  : 'Die Fehler kommen in der nächsten Runde wieder.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Insets.xl),
            FilledButton.icon(
              onPressed: onAgain,
              icon: const Icon(Icons.replay),
              label: const Text('Neue Runde'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NothingToType extends StatelessWidget {
  const _NothingToType();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: Insets.card,
        child: Text(
          'In diesem Thema ist nichts dabei, was sich kurz genug tippen '
          'lässt.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
