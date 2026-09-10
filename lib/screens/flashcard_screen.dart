import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/arabic_text.dart';
import '../widgets/flip_card.dart';
import '../widgets/level_dots.dart';
import '../widgets/speak_button.dart';

/// Flashcards with a flip: German on the front, Arabic and the
/// transliteration on the back — or the other way round.
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({
    super.key,
    this.entries,
    required this.title,
    this.accent,
    this.accentSoft,
    this.count,
    this.onFinished,
    this.embedded = false,
  });

  /// Die Wörter für diese Runde, oder `null` für die Tagesportion aus dem
  /// gesamten Bestand.
  final List<VocabEntry>? entries;
  final String title;
  final Color? accent;
  final Color? accentSoft;

  /// Wie viele Aufgaben die Runde hat. `null` heißt: die übliche Zahl.
  ///
  /// Zusammen mit [onFinished] und [embedded] macht das den Bildschirm zu
  /// einem Block einer Kurzrunde: kürzer, ohne eigene Bilanz und ohne
  /// eigenes Gerüst.
  final int? count;

  /// Wird statt der eigenen Schlussbilanz gerufen, sobald die Runde durch
  /// ist — die Kurzrunde hängt dann den nächsten Block an.
  final VoidCallback? onFinished;

  /// Ohne eigenes `Scaffold` und ohne Kopfzeile: Der Bildschirm sitzt in
  /// einem fremden Gerüst.
  final bool embedded;

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
    final LearningState state = LearningScope.of(context);
    final List<VocabEntry>? chosen = widget.entries;
    // Ein ausgewähltes Thema wird ganz durchgearbeitet; ohne Auswahl ist es
    // die Tagesportion. Ein Stapel mit über tausend Karten ist keine Übung,
    // sondern eine Drohung.
    _cards = chosen != null
        ? state.trainingOrder(List<VocabEntry>.of(chosen), random: _random)
        : state.dailySelection(random: _random);
    final int? limit = widget.count;
    if (limit != null && _cards.length > limit) {
      _cards = _cards.take(limit).toList();
    }
    _index = 0;
    _revealed = false;
  }

  void _rate({required bool known}) {
    AnswerFeedback.tap(correct: known);
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

  /// Legt das Gerüst um den Inhalt.
  ///
  /// In der App eine Kopfzeile mit Fortschrittsbalken; in einer Kurzrunde
  /// nichts davon — dort trägt der Rahmen den Fortschritt über die ganze
  /// Runde, und zwei Kopfzeilen übereinander wären nur im Weg.
  Widget _wrap(Widget body, {List<Widget> actions = const <Widget>[]}) {
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (actions.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Karteikarten · ${widget.title}'),
        actions: actions,
        bottom: _cards.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _index / _cards.length,
                  minHeight: 4,
                ),
              ),
      ),
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = widget.accent ?? theme.colorScheme.primary;

    if (_cards.isEmpty) {
      return _wrap(const Center(child: CircularProgressIndicator()));
    }

    if (_index >= _cards.length) {
      // In einer Kurzrunde übernimmt der Rahmen; hier gibt es keine eigene
      // Schlussbilanz, sonst stünden zwei hintereinander.
      final VoidCallback? fertig = widget.onFinished;
      if (fertig != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => fertig());
        // Nichts statt eines Ladekringels: Der Rahmen tauscht den Block im
        // nächsten Bild aus. Ein sich drehender Kringel wäre ein Flackern —
        // und wenn die Übergabe je hakte, ein Kringel ohne Ende.
        return _wrap(const SizedBox.shrink());
      }
      return _wrap(Center(
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
      ));
    }

    final VocabEntry card = _cards[_index];
    final LearningState state = LearningScope.of(context);

    return _wrap(
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
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Text('Karte ${_index + 1} von ${_cards.length}',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge),
                ),
                const SizedBox(width: Insets.sm),
                LevelDots(
                  box: state.boxOf(card),
                  color: accent,
                  softColor: widget.accentSoft,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Semantics(
                button: true,
                label: _revealed
                    ? 'Karte aufgedeckt. Zum Zudecken tippen.'
                    : 'Karte verdeckt. Zum Aufdecken tippen.',
                child: GestureDetector(
                  onTap: () => setState(() => _revealed = !_revealed),
                  child: FlipCard(
                    showBack: _revealed,
                    front: _CardFace(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_arabicFirst)
                            _SpokenWord(word: card.arabic, color: accent)
                          else
                            Text(
                              card.german,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          const SizedBox(height: Insets.xl),
                          Text(
                            'Zum Aufdecken tippen',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    back: _CardFace(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_arabicFirst)
                            Text(
                              card.german,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            )
                          else
                            _SpokenWord(word: card.arabic, color: accent),
                          if (card.transliteration.isNotEmpty) ...<Widget>[
                            const SizedBox(height: Insets.md),
                            Text(
                              card.transliteration,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                          if (card.explanation != null) ...<Widget>[
                            const SizedBox(height: Insets.md),
                            Text(
                              card.explanation!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ],
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

/// The Arabic word with a speaker button next to it.
class _SpokenWord extends StatelessWidget {
  const _SpokenWord({required this.word, required this.color});

  final String word;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: ArabicText(
            word,
            fontSize: 40,
            color: color,
            textAlign: TextAlign.center,
          ),
        ),
        SpeakButton(text: word, size: 28, color: color),
      ],
    );
  }
}

/// Die Fläche einer Karteikarte — beide Seiten sehen gleich aus, damit die
/// Drehung nicht springt.
class _CardFace extends StatelessWidget {
  const _CardFace({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}
