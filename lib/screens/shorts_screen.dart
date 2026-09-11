import 'dart:math';

import 'package:flutter/material.dart' hide Feedback;

import '../models/vocabulary.dart';
import '../widgets/share_result.dart';
import '../state/learning_state.dart';
import '../state/daily_quests.dart';
import '../state/quiz_builder.dart';
import '../state/reward_store.dart';
import '../state/shorts_feed.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_feedback.dart';

/// Ein Thema als Feed: eine Karte füllt den Schirm, nach oben wischen heißt
/// weiter.
///
/// **Warum keine Liste.** Im Wortschatz ist die Liste richtig: Man sucht ein
/// bestimmtes Wort, blättert zurück, schlägt nach. Wissen sucht man nicht —
/// man stößt darauf. Deshalb gibt es hier kein Suchfeld, keine Kartei und
/// keine Übungsleiste, sondern eine Karte nach der anderen: ein Gedanke,
/// weiter.
///
/// Fakt und Frage wechseln sich ab (siehe `buildShorts`). Wer eine Karte
/// überspringt, merkt es an der nächsten Frage — das ist das Gegenmittel
/// gegen bloßes Durchwischen.
class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key, required this.category});

  final VocabCategory category;

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final Random _random = Random();
  final PageController _controller = PageController();

  late List<ShortItem> _feed = buildShorts(
    category: widget.category,
    random: _random,
  );

  /// Was auf welcher Karte angetippt wurde — je Karte höchstens einmal.
  final Map<int, String> _gewaehlt = <int, String>{};

  int _index = 0;
  int _richtig = 0;

  /// Ob das Thema für die Tagesaufgabe schon gezählt wurde — „Nochmal"
  /// soll sie nicht ein zweites Mal erledigen.
  bool _gemeldet = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _fragen =>
      _feed.where((ShortItem i) => i.kind == ShortKind.frage).length;

  void _antworten(int seite, QuizQuestion frage, String option) {
    if (_gewaehlt.containsKey(seite)) return;
    final bool richtig = frage.isCorrect(option);
    final LearningState state = LearningScope.of(context);

    AnswerFeedback.tap(correct: richtig);
    state.recordAnswer(correct: richtig);
    if (richtig) {
      state.promote(frage.entry);
    } else {
      state.demote(frage.entry);
    }
    setState(() {
      _gewaehlt[seite] = option;
      if (richtig) _richtig++;
    });
  }

  void _weiter() {
    if (_index + 1 >= _feed.length + 1) return;
    _controller.nextPage(duration: Motion.normal, curve: Motion.enter);
  }

  void _nochmal() {
    setState(() {
      _feed = buildShorts(category: widget.category, random: _random);
      _gewaehlt.clear();
      _richtig = 0;
      _index = 0;
    });
    _controller.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Thema verlassen',
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(Insets.md),
          child: _StoryBalken(
            gesamt: _feed.length,
            index: _index,
            farbe: widget.category.color,
          ),
        ),
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: _feed.length + 1,
          onPageChanged: (int seite) {
            setState(() => _index = seite);
            // Durchgewischt bis zur Abschlusskarte: Das ist die Aufgabe.
            if (seite == _feed.length && !_gemeldet) {
              _gemeldet = true;
              RewardScope.maybeOf(context)?.report(QuestKind.feed);
              LearningScope.of(context).recordShortsFinished();
            }
          },
          itemBuilder: (BuildContext context, int seite) {
            if (seite == _feed.length) {
              return _Abschluss(
                thema: widget.category.name,
                richtig: _richtig,
                gesamt: _fragen,
                onNochmal: _nochmal,
                onFertig: () => Navigator.of(context).pop(),
              );
            }
            final ShortItem item = _feed[seite];
            return switch (item.kind) {
              ShortKind.fakt => _FaktKarte(
                  entry: item.entry,
                  farbe: widget.category.color,
                  onWeiter: _weiter,
                ),
              ShortKind.frage => _FrageKarte(
                  frage: item.question!,
                  gewaehlt: _gewaehlt[seite],
                  onAntwort: (String option) =>
                      _antworten(seite, item.question!, option),
                  onWeiter: _weiter,
                ),
            };
          },
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}

/// Der Balken über dem Feed: ein Strich je Karte, wie bei Stories.
///
/// Eine Zahl („7 von 15") wäre genauer, aber man liest sie nicht. Der Balken
/// sagt dasselbe nebenbei: wie weit es noch ist.
class _StoryBalken extends StatelessWidget {
  const _StoryBalken({
    required this.gesamt,
    required this.index,
    required this.farbe,
  });

  final int gesamt;
  final int index;
  final Color farbe;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (gesamt <= 0) return const SizedBox(height: Insets.md);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, 0, Insets.lg, Insets.sm),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < gesamt; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: AnimatedContainer(
                duration: Motion.fast,
                height: 3,
                decoration: BoxDecoration(
                  color: i <= index
                      ? farbe
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Eine Karte zum Lesen: Begriff, Bedeutung, ein Absatz dazu.
class _FaktKarte extends StatelessWidget {
  const _FaktKarte({
    required this.entry,
    required this.farbe,
    required this.onWeiter,
  });

  final VocabEntry entry;
  final Color farbe;
  final VoidCallback onWeiter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, Insets.xl, Insets.lg, Insets.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: farbe,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(height: Insets.lg),
                Text(
                  entry.german,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Insets.sm),
                Text(
                  entry.answer,
                  style: theme.textTheme.titleMedium?.copyWith(color: farbe),
                ),
                if (entry.explanation case final String erklaerung) ...<Widget>[
                  const SizedBox(height: Insets.xl),
                  Text(
                    erklaerung,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ),
        _WischHinweis(text: 'Weiter', onTap: onWeiter),
      ],
    );
  }
}

/// Eine Karte mit Frage: die Antworten stehen unten, in der Daumenzone.
///
/// Nach dem Antippen tritt die Erklärung an die Stelle der Frage — die
/// Antworten bleiben stehen, wo sie waren. So wächst nichts nach unten aus
/// dem Bild heraus, und der Blick bleibt, wo er schon ist.
class _FrageKarte extends StatelessWidget {
  const _FrageKarte({
    required this.frage,
    required this.gewaehlt,
    required this.onAntwort,
    required this.onWeiter,
  });

  final QuizQuestion frage;
  final String? gewaehlt;
  final ValueChanged<String> onAntwort;
  final VoidCallback onWeiter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? antwort = gewaehlt;
    final bool richtig = antwort != null && frage.isCorrect(antwort);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, Insets.xl, Insets.lg, Insets.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (antwort == null)
                  Text(
                    frage.prompt,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                  )
                else ...<Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        richtig ? Icons.check_circle : Icons.cancel,
                        size: 20,
                        color: richtig
                            ? Feedback.right(context)
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: Insets.sm),
                      Text(
                        richtig ? 'Richtig' : 'Daneben',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: richtig
                              ? Feedback.right(context)
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  Text(
                    frage.prompt,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (frage.explanation case final String erklaerung) ...<Widget>[
                    const SizedBox(height: Insets.md),
                    Text(
                      erklaerung,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        // Die vier Antworten stehen eng untereinander am unteren Rand: Dort
        // ist der Daumen, ohne dass die Hand umgreifen muss.
        Padding(
          padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final String option in frage.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: _Antwort(
                    label: option,
                    zustand: antwort == null
                        ? _AntwortZustand.offen
                        : frage.isCorrect(option)
                            ? _AntwortZustand.richtig
                            : option == antwort
                                ? _AntwortZustand.falsch
                                : _AntwortZustand.blass,
                    onTap: () => onAntwort(option),
                  ),
                ),
            ],
          ),
        ),
        _WischHinweis(
          text: antwort == null ? 'Überspringen' : 'Weiter',
          onTap: onWeiter,
        ),
      ],
    );
  }
}

/// Der Hinweis am unteren Rand, dass es nach oben weitergeht.
///
/// Er ist **angeheftet**, nicht Teil des Scrollbereichs — und er ist zugleich
/// antippbar. Wischen ist der Weg; wer die Geste nicht kennt oder gerade in
/// einem langen Text steckt, kommt trotzdem vorwärts.
class _WischHinweis extends StatelessWidget {
  const _WischHinweis({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm, top: Insets.xs),
      child: Center(
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.keyboard_arrow_up, size: 20),
          label: Text(text),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            minimumSize: const Size(0, kMinTapTarget),
          ),
        ),
      ),
    );
  }
}

/// Die letzte Karte: was saß, und wie es weitergeht.
class _Abschluss extends StatelessWidget {
  const _Abschluss({
    required this.thema,
    required this.richtig,
    required this.gesamt,
    required this.onNochmal,
    required this.onFertig,
  });

  final String thema;
  final int richtig;
  final int gesamt;
  final VoidCallback onNochmal;
  final VoidCallback onFertig;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: Insets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: Insets.xl),
                Icon(Icons.done_all,
                    size: 44, color: theme.colorScheme.primary),
                const SizedBox(height: Insets.md),
                Text('Thema durch', style: theme.textTheme.headlineSmall),
                const SizedBox(height: Insets.md),
                Text(
                  gesamt == 0
                      ? 'Alles gelesen.'
                      : '$richtig von $gesamt Fragen saßen.',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: Insets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FilledButton(
                  onPressed: onNochmal, child: const Text('Nochmal')),
              const SizedBox(height: Insets.sm),
              OutlinedButton(
                  onPressed: onFertig, child: const Text('Nächstes Thema')),
              if (gesamt > 0)
                ShareResultButton(
                  was: thema,
                  richtig: richtig,
                  gesamt: gesamt,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _AntwortZustand { offen, richtig, falsch, blass }

class _Antwort extends StatelessWidget {
  const _Antwort({
    required this.label,
    required this.zustand,
    required this.onTap,
  });

  final String label;
  final _AntwortZustand zustand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? rand = switch (zustand) {
      _AntwortZustand.richtig => Feedback.right(context),
      _AntwortZustand.falsch => theme.colorScheme.error,
      _ => null,
    };

    return OutlinedButton(
      onPressed: zustand == _AntwortZustand.offen ? onTap : null,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.md, vertical: Insets.sm),
        side: rand == null ? null : BorderSide(color: rand, width: 2),
        disabledForegroundColor: zustand == _AntwortZustand.blass
            ? theme.disabledColor
            : theme.colorScheme.onSurface,
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          if (zustand == _AntwortZustand.richtig)
            Icon(Icons.check, size: 20, color: rand)
          else if (zustand == _AntwortZustand.falsch)
            Icon(Icons.close, size: 20, color: rand),
        ],
      ),
    );
  }
}
