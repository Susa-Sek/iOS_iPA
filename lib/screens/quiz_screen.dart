import 'dart:math';

import 'package:flutter/material.dart';

import '../data/vocabulary_data.dart';
import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../state/speech.dart';
import '../widgets/arabic_text.dart';
import '../widgets/speak_button.dart';

/// Which way round the quiz asks.
enum QuizDirection {
  /// Arabic word is shown, the German meaning has to be picked.
  arabicToGerman,

  /// German word is shown, the Arabic word has to be picked.
  germanToArabic,

  /// Only the spoken word is given — the hardest and most useful direction.
  listening;

  String get label => switch (this) {
        QuizDirection.arabicToGerman => 'Arabisch → Deutsch',
        QuizDirection.germanToArabic => 'Deutsch → Arabisch',
        QuizDirection.listening => 'Hören → Deutsch',
      };
}

/// Multiple-choice quiz in both directions. Words that are still weak are
/// asked first, a wrong answer sends a word back to the first Leitner box.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    this.entries,
    required this.title,
    this.direction = QuizDirection.arabicToGerman,
  });

  /// The pool to draw questions from, or `null` for the whole vocabulary.
  final List<VocabEntry>? entries;
  final String title;
  final QuizDirection direction;

  static const int questionsPerRound = 10;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Random _random = Random();

  late List<VocabEntry> _pool;
  late QuizDirection _direction;
  List<_Question> _questions = <_Question>[];

  int _index = 0;
  int _correct = 0;
  VocabEntry? _chosen;

  @override
  void initState() {
    super.initState();
    _direction = widget.direction;
    _pool = List<VocabEntry>.of(widget.entries ?? kAllEntries);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(_buildQuestions);
    });
  }

  /// Weak words first, so a round trains what is actually missing.
  void _buildQuestions() {
    final List<VocabEntry> ordered =
        LearningScope.of(context).trainingOrder(_pool, random: _random);
    final int count = min(QuizScreen.questionsPerRound, ordered.length);
    _questions = <_Question>[
      for (final VocabEntry entry in ordered.take(count))
        _Question(entry: entry, options: _optionsFor(entry)),
    ];
    _index = 0;
    _correct = 0;
    _chosen = null;
  }

  /// The right answer plus up to three distractors, shuffled.
  List<VocabEntry> _optionsFor(VocabEntry entry) {
    final List<VocabEntry> options = <VocabEntry>[entry];
    final List<VocabEntry> candidates =
        List<VocabEntry>.of(_pool.length >= 4 ? _pool : kAllEntries)
          ..shuffle(_random);

    for (final VocabEntry candidate in candidates) {
      if (options.length == 4) break;
      final bool clash = options.any((VocabEntry o) =>
          o.german == candidate.german || o.arabic == candidate.arabic);
      if (!clash) options.add(candidate);
    }
    return options..shuffle(_random);
  }

  void _answer(_Question question, VocabEntry option) {
    if (_chosen != null) return;
    final bool correct = option.id == question.entry.id;
    final LearningState state = LearningScope.of(context);
    state.recordAnswer(correct: correct);
    if (correct) {
      state.promote(question.entry);
      _correct++;
    } else {
      state.demote(question.entry);
    }
    setState(() => _chosen = option);

    // Letzte Frage richtig und keine einzige daneben: perfekte Runde.
    if (_index == _questions.length - 1 &&
        _correct == _questions.length &&
        _questions.length >= 5) {
      state.recordPerfectRound();
    }
  }

  void _next() {
    setState(() {
      _chosen = null;
      _index++;
    });
    _speakIfListening();
  }

  /// Cycles through the directions. "Hören" is skipped when the device has
  /// no Arabic voice — a listening quiz without sound would be unanswerable.
  void _nextDirection() {
    final Speaker speaker = SpeechScope.of(context);
    final List<QuizDirection> available = <QuizDirection>[
      QuizDirection.arabicToGerman,
      QuizDirection.germanToArabic,
      if (speaker.isAvailable) QuizDirection.listening,
    ];
    final int index = available.indexOf(_direction);
    setState(() {
      _direction = available[(index + 1) % available.length];
      _buildQuestions();
    });
    _speakIfListening();
  }

  /// In the listening direction the word is played as soon as it appears.
  void _speakIfListening() {
    if (_direction != QuizDirection.listening) return;
    if (_index >= _questions.length) return;
    SpeechScope.of(context).speak(_questions[_index].entry.arabic);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool arabicPrompt = _direction == QuizDirection.arabicToGerman;
    final bool listening = _direction == QuizDirection.listening;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz · ${widget.title}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Richtung: ${_direction.label}',
            icon: Icon(listening ? Icons.hearing : Icons.swap_horiz),
            onPressed: _nextDirection,
          ),
        ],
        bottom: _questions.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _index / _questions.length,
                  minHeight: 4,
                ),
              ),
      ),
      body: _buildBody(theme, arabicPrompt, listening),
    );
  }

  Widget _buildBody(ThemeData theme, bool arabicPrompt, bool listening) {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_index >= _questions.length) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _correct == _questions.length
                  ? Icons.workspace_premium_outlined
                  : Icons.insights_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('$_correct von ${_questions.length} richtig',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_correct == _questions.length
                ? 'Perfekte Runde!'
                : 'Die Fehler kommen in der nächsten Runde wieder.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.replay),
              label: const Text('Neue Runde'),
              onPressed: () => setState(_buildQuestions),
            ),
          ],
        ),
      );
    }

    final _Question question = _questions[_index];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Frage ${_index + 1} von ${_questions.length}',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Card(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: <Widget>[
                  if (listening) ...<Widget>[
                    IconButton.filled(
                      iconSize: 44,
                      tooltip: 'Nochmal anhören',
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => SpeechScope.of(context)
                          .speak(question.entry.arabic),
                    ),
                    const SizedBox(height: 10),
                    if (_chosen == null)
                      Text(
                        'Welches Wort hörst du?',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                      )
                    else ...<Widget>[
                      ArabicText(
                        question.entry.arabic,
                        fontSize: 30,
                        color: theme.colorScheme.primary,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        question.entry.transliteration,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ] else if (arabicPrompt) ...<Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: ArabicText(
                            question.entry.arabic,
                            fontSize: 36,
                            color: theme.colorScheme.primary,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SpeakButton(
                          text: question.entry.arabic,
                          size: 26,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.entry.transliteration,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ] else
                    Text(
                      question.entry.german,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 2,
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int i) {
                final VocabEntry option = question.options[i];
                return _AnswerButton(
                  option: option,
                  arabic: !arabicPrompt,
                  state: _stateFor(question, option),
                  onTap: () => _answer(question, option),
                );
              },
            ),
          ),
          if (_chosen != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton(
                onPressed: _next,
                child: Text(_index == _questions.length - 1
                    ? 'Ergebnis ansehen'
                    : 'Weiter'),
              ),
            ),
        ],
      ),
    );
  }

  _AnswerState _stateFor(_Question question, VocabEntry option) {
    if (_chosen == null) return _AnswerState.open;
    if (option.id == question.entry.id) return _AnswerState.correct;
    if (option.id == _chosen!.id) return _AnswerState.wrong;
    return _AnswerState.muted;
  }
}

enum _AnswerState { open, correct, wrong, muted }

class _Question {
  const _Question({required this.entry, required this.options});

  final VocabEntry entry;
  final List<VocabEntry> options;
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.option,
    required this.arabic,
    required this.state,
    required this.onTap,
  });

  final VocabEntry option;
  final bool arabic;
  final _AnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Color? background;
    Color? foreground;
    switch (state) {
      case _AnswerState.correct:
        background = const Color(0xFF2E7D32);
        foreground = Colors.white;
        break;
      case _AnswerState.wrong:
        background = theme.colorScheme.error;
        foreground = theme.colorScheme.onError;
        break;
      case _AnswerState.muted:
        foreground = theme.disabledColor;
        break;
      case _AnswerState.open:
        break;
    }

    return OutlinedButton(
      onPressed: state == _AnswerState.open ? onTap : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledForegroundColor: foreground,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        alignment: arabic ? Alignment.centerRight : Alignment.centerLeft,
      ),
      child: arabic
          ? ArabicText(option.arabic, fontSize: 24, color: foreground)
          : Text(
              option.german,
              style: theme.textTheme.titleMedium?.copyWith(color: foreground),
            ),
    );
  }
}
