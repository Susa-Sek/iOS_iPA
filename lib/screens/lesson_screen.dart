import 'dart:math';

import 'package:flutter/material.dart' hide Feedback;

import '../data/knowledge/lessons.dart';
import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../state/lesson_store.dart';
import '../state/quiz_builder.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_feedback.dart';

/// Eine Lektion: lesen, prüfen, mitnehmen.
///
/// Der Ablauf ist der ganze Unterschied zur Kartei. Auf den Lesekarten gibt
/// es **nichts zu bewerten** — kein „Kann ich", kein Ankreuzen, keine
/// Selbsteinschätzung. Man liest. Erst danach wird gefragt, und zwar zu genau
/// dem, was gerade stand.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final KnowledgeLesson lesson;

  /// Wie viele Fragen aus früheren Lektionen vorweg wiederholt werden.
  static const int maxRecap = 2;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

/// Die Abschnitte einer Lektion, in dieser Reihenfolge.
enum _Phase { recap, intro, reading, checks, takeaway }

class _LessonScreenState extends State<LessonScreen> {
  final Random _random = Random();

  bool _vorbereitet = false;
  List<QuizQuestion> _recap = <QuizQuestion>[];
  List<QuizQuestion> _fragen = <QuizQuestion>[];

  _Phase _phase = _Phase.intro;
  int _index = 0;
  String? _gewaehlt;
  int _richtig = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vorbereitet) return;
    _vorbereitet = true;
    _vorbereiten();
  }

  void _vorbereiten() {
    final LearningState state = LearningScope.of(context);
    final KnowledgeLesson lesson = widget.lesson;

    // Nachfassen: Fragen aus **anderen** Lektionen, die fällig sind. Das ist
    // die ganze sichtbare Wiederholung im Wissen — keine Fächer, keine
    // Termine, keine Zahl, die einen anstarrt.
    final Set<String> eigene = <String>{
      for (final VocabEntry e in lesson.entries) e.id,
    };
    // `repetitionsDue`, nicht `dueEntries`: Nachgefasst wird nur, was schon
    // einmal dran war. Sonst begönne die erste Lektion überhaupt mit zwei
    // Fragen zu Stoff, den man noch nie gesehen hat.
    final List<VocabEntry> nachzufassen = <VocabEntry>[
      for (final VocabEntry e in state.repetitionsDue())
        if (e.question != null && !eigene.contains(e.id)) e,
    ]..shuffle(_random);

    _recap = buildQuizRound(
      ordered: nachzufassen.take(LessonScreen.maxRecap).toList(),
      pool: state.activeEntries,
      direction: QuizDirection.arabicToGerman,
      random: _random,
      count: LessonScreen.maxRecap,
    );

    _fragen = buildQuizRound(
      ordered: lesson.checks,
      pool: lesson.entries.isNotEmpty ? lesson.entries : state.activeEntries,
      direction: QuizDirection.arabicToGerman,
      random: _random,
      count: lesson.checks.length,
    );

    _phase = _recap.isEmpty ? _Phase.intro : _Phase.recap;
    _index = 0;
    _gewaehlt = null;
    _richtig = 0;
  }

  List<QuizQuestion> get _aktuelleFragen =>
      _phase == _Phase.recap ? _recap : _fragen;

  void _antworten(QuizQuestion frage, String option) {
    if (_gewaehlt != null) return;
    final bool richtig = frage.isCorrect(option);
    final LearningState state = LearningScope.of(context);

    AnswerFeedback.tap(correct: richtig);
    state.recordAnswer(correct: richtig);
    if (richtig) {
      state.promote(frage.entry);
      if (_phase == _Phase.checks) _richtig++;
    } else {
      state.demote(frage.entry);
    }
    setState(() => _gewaehlt = option);
  }

  void _weiter() {
    setState(() {
      switch (_phase) {
        case _Phase.recap:
          _gewaehlt = null;
          if (_index + 1 < _recap.length) {
            _index++;
          } else {
            _phase = _Phase.intro;
            _index = 0;
          }
        case _Phase.intro:
          _phase = _Phase.reading;
          _index = 0;
        case _Phase.reading:
          if (_index + 1 < widget.lesson.reading.length) {
            _index++;
          } else {
            _phase = _Phase.checks;
            _index = 0;
          }
        case _Phase.checks:
          _gewaehlt = null;
          if (_index + 1 < _fragen.length) {
            _index++;
          } else {
            _phase = _Phase.takeaway;
            _index = 0;
            LessonScope.of(context).markDone(widget.lesson.id);
          }
        case _Phase.takeaway:
          Navigator.of(context).pop();
      }
    });
  }

  /// Wie weit die Lektion ist, über alle Abschnitte.
  double get _fortschritt {
    final int gesamt = _recap.length +
        1 +
        widget.lesson.reading.length +
        _fragen.length;
    if (gesamt == 0) return 1;
    final int erledigt = switch (_phase) {
      _Phase.recap => _index,
      _Phase.intro => _recap.length,
      _Phase.reading => _recap.length + 1 + _index,
      _Phase.checks =>
        _recap.length + 1 + widget.lesson.reading.length + _index,
      _Phase.takeaway => gesamt,
    };
    return (erledigt / gesamt).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Lektion verlassen',
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: _fortschritt, minHeight: 4),
        ),
      ),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.recap => _frage(theme, nachfassen: true),
          _Phase.intro => _Einstieg(lesson: widget.lesson, onWeiter: _weiter),
          _Phase.reading => _Lesekarte(
              entry: widget.lesson.reading[_index],
              nummer: _index + 1,
              gesamt: widget.lesson.reading.length,
              onWeiter: _weiter,
            ),
          _Phase.checks => _frage(theme, nachfassen: false),
          _Phase.takeaway => _Fazit(
              lesson: widget.lesson,
              richtig: _richtig,
              gesamt: _fragen.length,
              onFertig: _weiter,
            ),
        },
      ),
    );
  }

  Widget _frage(ThemeData theme, {required bool nachfassen}) {
    final List<QuizQuestion> fragen = _aktuelleFragen;
    if (fragen.isEmpty) return const SizedBox.shrink();
    final QuizQuestion frage = fragen[_index];
    final String? gewaehlt = _gewaehlt;

    // „Weiter" steht fest unter der Liste, nicht darin. Bei großer Schrift
    // auf einem kleinen Telefon läge es sonst unter dem Rand — und der
    // einzige Weg nach vorn wäre nicht zu sehen.
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
      padding: Insets.card,
      children: <Widget>[
        Text(
          nachfassen
              ? 'Kurz nachgefasst · ${_index + 1} von ${fragen.length}'
              : 'Frage ${_index + 1} von ${fragen.length}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: nachfassen
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: Insets.md),
        // Bewusst zurückhaltend gesetzt: Bei großer Systemschrift füllte
        // eine Frage im Titelgrad allein den Bildschirm, und die Antworten
        // standen darunter, ohne dass man sie sah.
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Insets.md, vertical: Insets.md),
            child: Text(
              frage.prompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: Insets.md),
        for (final String option in frage.options) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: _Antwort(
              label: option,
              zustand: gewaehlt == null
                  ? _AntwortZustand.offen
                  : frage.isCorrect(option)
                      ? _AntwortZustand.richtig
                      : option == gewaehlt
                          ? _AntwortZustand.falsch
                          : _AntwortZustand.blass,
              onTap: () => _antworten(frage, option),
            ),
          ),
        ],
        if (gewaehlt != null) ...<Widget>[
          const SizedBox(height: Insets.sm),
          if (frage.entry.explanation case final String erklaerung)
            _Erklaerung(text: erklaerung),
        ],
      ],
          ),
        ),
        if (gewaehlt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, 0, Insets.lg, Insets.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _weiter, child: const Text('Weiter')),
            ),
          ),
      ],
    );
  }
}

/// Der Einstieg: ein Satz, worum es geht.
class _Einstieg extends StatelessWidget {
  const _Einstieg({required this.lesson, required this.onWeiter});

  final KnowledgeLesson lesson;
  final VoidCallback onWeiter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: Insets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: Insets.xl),
                Icon(Icons.menu_book_outlined,
                    size: 40, color: theme.colorScheme.primary),
                const SizedBox(height: Insets.lg),
                Text(lesson.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: Insets.md),
                Text(lesson.intro,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                const SizedBox(height: Insets.lg),
                Text(
                  '${lesson.reading.length} zum Lesen · '
                  '${lesson.checks.length} Fragen',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: Insets.card,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: onWeiter, child: const Text('Los geht’s')),
          ),
        ),
      ],
    );
  }
}

/// Eine Lesekarte. Hier gibt es **nichts zu bewerten** — nur zu lesen.
class _Lesekarte extends StatelessWidget {
  const _Lesekarte({
    required this.entry,
    required this.nummer,
    required this.gesamt,
    required this.onWeiter,
  });

  final VocabEntry entry;
  final int nummer;
  final int gesamt;
  final VoidCallback onWeiter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: Insets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Lesen · $nummer von $gesamt',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: Insets.xl),
                Text(entry.german,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: Insets.sm),
                Text(entry.answer,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary)),
                if (entry.explanation case final String erklaerung) ...<Widget>[
                  const SizedBox(height: Insets.lg),
                  Text(erklaerung,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: Insets.card,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: onWeiter, child: const Text('Weiter')),
          ),
        ),
      ],
    );
  }
}

/// Der Schluss: was hängen bleiben soll.
class _Fazit extends StatelessWidget {
  const _Fazit({
    required this.lesson,
    required this.richtig,
    required this.gesamt,
    required this.onFertig,
  });

  final KnowledgeLesson lesson;
  final int richtig;
  final int gesamt;
  final VoidCallback onFertig;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: Insets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: Insets.lg),
                Icon(Icons.check_circle_outline,
                    size: 44, color: theme.colorScheme.primary),
                const SizedBox(height: Insets.md),
                Text('Das nimmst du mit',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: Insets.lg),
                for (final String satz in lesson.takeaway)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 10),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(satz,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: Insets.lg),
                Text(
                  gesamt == 0
                      ? 'Lektion abgeschlossen.'
                      : '$richtig von $gesamt Fragen richtig.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: Insets.card,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: onFertig, child: const Text('Fertig')),
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
            horizontal: Insets.lg, vertical: Insets.md),
        side: rand == null ? null : BorderSide(color: rand, width: 2),
        disabledForegroundColor: zustand == _AntwortZustand.blass
            ? theme.disabledColor
            : theme.colorScheme.onSurface,
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          if (zustand == _AntwortZustand.richtig)
            Icon(Icons.check, color: rand)
          else if (zustand == _AntwortZustand.falsch)
            Icon(Icons.close, color: rand),
        ],
      ),
    );
  }
}

class _Erklaerung extends StatelessWidget {
  const _Erklaerung({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: Insets.card,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: Radii.cardShape,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.lightbulb_outline,
              size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
