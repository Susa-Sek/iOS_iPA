import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../state/quiz_builder.dart';
import '../state/speech.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/arabic_text.dart';
import '../widgets/speak_button.dart';

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

  static const int questionsPerRound = kQuestionsPerRound;

  /// Der scrollbare Körper einer Frage — benannt, damit Tests eindeutig
  /// diese Liste scrollen können.
  static const Key bodyKey = Key('quiz-body');

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Random _random = Random();

  /// Für die Antwortliste, damit die Erklärung nach dem Antworten von selbst
  /// in den Blick rückt.
  final ScrollController _answers = ScrollController();

  late List<VocabEntry> _pool;
  late QuizDirection _direction;
  List<QuizQuestion> _questions = <QuizQuestion>[];

  int _index = 0;
  int _correct = 0;
  String? _chosen;

  @override
  void initState() {
    super.initState();
    _direction = widget.direction;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Der Vorrat kommt aus der Registry, nicht mehr aus einem festen
      // Datensatz — so übt "Alle Wörter" auch neue Fächer mit.
      _pool = List<VocabEntry>.of(
          widget.entries ?? LearningScope.of(context).content.entries);
      setState(_buildQuestions);
    });
  }

  /// Weak words first, so a round trains what is actually missing.
  void _buildQuestions() {
    _questions = buildQuizRound(
      ordered: LearningScope.of(context).trainingOrder(_pool, random: _random),
      pool: _pool,
      direction: _direction,
      random: _random,
    );
    _index = 0;
    _correct = 0;
    _chosen = null;
  }

  @override
  void dispose() {
    _answers.dispose();
    super.dispose();
  }

  void _answer(QuizQuestion question, String option) {
    if (_chosen != null) return;
    final bool correct = question.isCorrect(option);
    final LearningState state = LearningScope.of(context);
    AnswerFeedback.tap(correct: correct);
    state.recordAnswer(correct: correct);
    if (correct) {
      state.promote(question.entry);
      _correct++;
    } else {
      state.demote(question.entry);
    }
    setState(() => _chosen = option);
    _showExplanation();

    // Letzte Frage richtig und keine einzige daneben: perfekte Runde.
    if (_index == _questions.length - 1 &&
        _correct == _questions.length &&
        _questions.length >= 5) {
      state.recordPerfectRound();
    }
  }

  /// Die Erklärung steht unter den vier Antworten. Auf einem kleinen
  /// Telefon liegt sie damit unter dem Rand — wer sie erst suchen muss,
  /// liest sie nicht. Also rückt sie selbst in den Blick.
  void _showExplanation() {
    if (_questions[_index].entry.explanation == null) return;
    // Zwei Durchgänge: Der erste rückt so weit, wie die Liste gebaut ist,
    // der zweite trifft das Ende, das dabei erst entstanden ist.
    void rutschen(int uebrig) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wer inzwischen weitergeblättert hat, will nicht, dass ein
        // nachlaufender Ruck die neue Frage aus dem Bild schiebt.
        if (!mounted || _chosen == null || !_answers.hasClients) return;
        final double ziel = _answers.position.maxScrollExtent;
        if (_answers.offset >= ziel) return;
        _answers.animateTo(ziel,
            duration: Motion.normal, curve: Motion.enter);
        if (uebrig > 0) rutschen(uebrig - 1);
      });
    }

    rutschen(2);
  }

  void _next() {
    setState(() {
      _chosen = null;
      _index++;
    });
    if (_answers.hasClients) _answers.jumpTo(0);
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

    final QuizQuestion question = _questions[_index];

    // Frage, Antworten und Erklärung scrollen gemeinsam; „Weiter" bleibt
    // darunter stehen. Wissensfragen bringen ganze Sätze mit — läge der
    // Knopf in der Liste, stünde er auf kleinen Telefonen unter dem Rand,
    // und der wichtigste Griff der Übung wäre nicht zu erreichen.
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            // Benannt, damit Tests eindeutig diese Liste scrollen können.
            key: QuizScreen.bodyKey,
            controller: _answers,
            padding: const EdgeInsets.all(20),
            children: <Widget>[
          Text(
            'Frage ${_index + 1} von ${_questions.length}',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
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
                  ] else if (question.promptIsArabic) ...<Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: ArabicText(
                            question.prompt,
                            fontSize: 36,
                            color: theme.colorScheme.primary,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SpeakButton(
                          text: question.prompt,
                          size: 26,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    if (question.entry.transliteration.isNotEmpty) ...<Widget>[
                      const SizedBox(height: Insets.sm),
                      Text(
                        question.entry.transliteration,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ] else
                    Text(
                      question.prompt,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < question.options.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            _AnswerButton(
              label: question.options[i],
              arabic: question.answersAreArabic,
              state: _stateFor(question, question.options[i]),
              onTap: () => _answer(question, question.options[i]),
            ),
          ],
          RevealBox(
            visible: _chosen != null && question.entry.explanation != null,
            child: Padding(
              padding: const EdgeInsets.only(top: Insets.md),
              child: _Explanation(entry: question.entry),
            ),
          ),
            ],
          ),
        ),
        if (_chosen != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_index == _questions.length - 1
                    ? 'Ergebnis ansehen'
                    : 'Weiter'),
              ),
            ),
          ),
      ],
    );
  }

  _AnswerState _stateFor(QuizQuestion question, String option) {
    if (_chosen == null) return _AnswerState.open;
    if (question.isCorrect(option)) return _AnswerState.correct;
    if (option == _chosen) return _AnswerState.wrong;
    return _AnswerState.muted;
  }
}

enum _AnswerState { open, correct, wrong, muted }

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.arabic,
    required this.state,
    required this.onTap,
  });

  final String label;
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

    final Widget content = arabic
        ? ArabicText(label, fontSize: 24, color: foreground)
        : Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(color: foreground),
          );

    // Farbe allein trägt die Rückmeldung nicht — im Dunkeln, bei
    // Farbenblindheit oder aus dem Augenwinkel. Deshalb das Zeichen dazu.
    final bool decided =
        state == _AnswerState.correct || state == _AnswerState.wrong;

    return Semantics(
      button: true,
      enabled: state == _AnswerState.open,
      label: decided
          ? '$label, '
              '${AnswerFeedback.label(correct: state == _AnswerState.correct)}'
          : null,
      child: OutlinedButton(
        onPressed: state == _AnswerState.open ? onTap : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledForegroundColor: foreground,
          padding: const EdgeInsets.symmetric(
              vertical: Insets.lg, horizontal: Insets.lg),
          alignment: arabic ? Alignment.centerRight : Alignment.centerLeft,
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: content),
            if (decided)
              Icon(
                AnswerFeedback.icon(
                    correct: state == _AnswerState.correct),
                color: foreground,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Die Erklärung nach der Antwort — bei Wissensfragen der eigentliche
/// Lerneffekt, deshalb bekommt sie eine eigene Fläche statt einer Fußnote.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.entry});

  final VocabEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.lightbulb_outline,
                size: 20, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.explanation ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  if (entry.source != null) ...<Widget>[
                    const SizedBox(height: Insets.xs),
                    Text(
                      'Quelle: ${entry.source}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
