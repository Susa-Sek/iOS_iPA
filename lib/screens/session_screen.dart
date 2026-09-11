import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../widgets/share_result.dart';
import '../state/learning_state.dart';
import '../state/daily_quests.dart';
import '../state/reward_store.dart';
import '../state/session_plan.dart';
import '../theme/app_theme.dart';
import 'build_word_screen.dart';
import 'flashcard_screen.dart';
import 'matching_screen.dart';
import 'quiz_screen.dart';
import 'typing_screen.dart';

/// Die Kurzrunde: zwei Minuten, mehrere Übungsarten hintereinander.
///
/// Der Sinn ist das Zwischendurch. Wer das Telefon in die Hand nimmt, soll
/// einen Griff tun und beschäftigt sein — nicht erst einen Bereich, dann eine
/// Übung und dann eine Richtung wählen. Und weil jede Art nur wenige Aufgaben
/// hat, wird es nicht zäh.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, this.pool});

  /// Der Vorrat. Ohne Angabe die Tagesportion des aktiven Fachs.
  final List<VocabEntry>? pool;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final Random _random = Random();

  List<SessionBlock> _blocks = <SessionBlock>[];
  bool _geplant = false;
  int _block = 0;

  /// Punkte und Antworten beim Start, um am Ende die Bilanz zu ziehen.
  int _xpVorher = 0;
  int _antwortenVorher = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_geplant) return;
    _geplant = true;
    _planen();
  }

  void _planen() {
    final LearningState state = LearningScope.of(context);
    _blocks = buildSession(
      pool: widget.pool ?? state.dailySelection(random: _random),
      random: _random,
      suitability: suitabilityFor(
        wortBauen: BuildWordScreen.isSuitable,
        zuordnen: MatchingScreen.isSuitable,
      ),
    );
    _block = 0;
    _xpVorher = state.xp;
    _antwortenVorher = state.answered;
  }

  void _weiter() {
    if (!mounted) return;
    setState(() => _block++);
    // Der letzte Block ist durch: Die Kurzrunde zählt als erledigt.
    if (_block >= _blocks.length && _blocks.isNotEmpty) {
      RewardScope.maybeOf(context)?.report(QuestKind.kurzrunde);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool fertig = _block >= _blocks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurzrunde'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Abbrechen',
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: _blocks.isEmpty || fertig
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: _Fortschritt(blocks: _blocks, aktuell: _block),
              ),
      ),
      body: _blocks.isEmpty
          ? const _NichtsZuTun()
          : fertig
              ? _Bilanz(
                  aufgaben: sessionLength(_blocks),
                  punkte: LearningScope.of(context).xp - _xpVorher,
                  beantwortet:
                      LearningScope.of(context).answered - _antwortenVorher,
                  arten: _blocks.map((SessionBlock b) => b.kind).toList(),
                  onNochmal: () => setState(_planen),
                )
              // Der Schlüssel sorgt dafür, dass zwei Blöcke derselben Art
              // nicht ihren Zustand teilen — sonst liefe der zweite mit den
              // Karten des ersten weiter.
              : KeyedSubtree(
                  key: ValueKey<int>(_block),
                  child: _uebung(_blocks[_block], theme),
                ),
    );
  }

  Widget _uebung(SessionBlock block, ThemeData theme) {
    final List<VocabEntry> entries = block.entries;
    return switch (block.kind) {
      ExerciseKind.karteikarten => FlashcardScreen(
          entries: entries,
          title: 'Kurzrunde',
          count: entries.length,
          onFinished: _weiter,
          embedded: true,
        ),
      ExerciseKind.quiz => QuizScreen(
          entries: entries,
          title: 'Kurzrunde',
          count: entries.length,
          onFinished: _weiter,
          embedded: true,
        ),
      ExerciseKind.zuordnen => MatchingScreen(
          entries: entries,
          title: 'Kurzrunde',
          count: entries.length,
          onFinished: _weiter,
          embedded: true,
        ),
      ExerciseKind.wortBauen => BuildWordScreen(
          entries: entries,
          title: 'Kurzrunde',
          count: entries.length,
          onFinished: _weiter,
          embedded: true,
        ),
      ExerciseKind.tippen => TypingScreen(
          entries: entries,
          title: 'Kurzrunde',
          count: entries.length,
          onFinished: _weiter,
          embedded: true,
        ),
    };
  }
}

/// Zeigt, wie weit die **ganze** Runde ist — nicht nur der laufende Block.
///
/// Das ist der Unterschied zu drei Übungen hintereinander: Man sieht, dass es
/// gleich vorbei ist, und hört deshalb nicht mittendrin auf.
class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.blocks, required this.aktuell});

  final List<SessionBlock> blocks;
  final int aktuell;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, 0, Insets.lg, Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < blocks.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: Insets.xs),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= aktuell
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            // „Übungen" ausgeschrieben: Sonst steht über einer Quizfrage
            // „Quiz · 1 von 3" und darunter „Frage 1 von 3" — zwei Zählungen,
            // die dasselbe zu sagen scheinen und es nicht tun.
            '${blocks[aktuell].kind.label} · ${aktuell + 1}. von '
            '${blocks.length} Übungen',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Bilanz extends StatelessWidget {
  const _Bilanz({
    required this.aufgaben,
    required this.punkte,
    required this.beantwortet,
    required this.arten,
    required this.onNochmal,
  });

  final int aufgaben;
  final int punkte;
  final int beantwortet;
  final List<ExerciseKind> arten;
  final VoidCallback onNochmal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: Insets.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle_outline,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: Insets.lg),
            Text('Runde geschafft', style: theme.textTheme.headlineSmall),
            const SizedBox(height: Insets.sm),
            Text(
              '$aufgaben Aufgaben in ${arten.length} Übungsarten',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.lg),
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.sm,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (final ExerciseKind kind in arten)
                  Chip(
                    label: Text(kind.label),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            if (punkte > 0)
              Text('+$punkte Punkte',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: Insets.xl),
            FilledButton.icon(
              onPressed: onNochmal,
              icon: const Icon(Icons.replay),
              label: const Text('Noch eine Runde'),
            ),
            const SizedBox(height: Insets.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fertig'),
            ),
            ShareResultButton(
              was: 'Kurzrunde',
              richtig: beantwortet,
              gesamt: aufgaben,
            ),
          ],
        ),
      ),
    );
  }
}

class _NichtsZuTun extends StatelessWidget {
  const _NichtsZuTun();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: Insets.card,
        child: Text(
          'In diesem Fach ist gerade nichts zusammenzustellen.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
