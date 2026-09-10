import 'package:flutter/material.dart';

import '../state/learning_state.dart';
import '../state/quiz_builder.dart';
import '../state/speech.dart';
import '../theme/app_theme.dart';
import '../widgets/speak_button.dart';
import 'alphabet_screen.dart';
import 'build_word_screen.dart';
import 'flashcard_screen.dart';
import 'matching_screen.dart';
import 'quiz_screen.dart';
import 'quran_screen.dart';
import 'session_screen.dart';
import 'typing_screen.dart';
import 'verbs_screen.dart';

/// „Üben": alle Übungen und alles zum Nachschlagen, jeweils mit einem Satz,
/// der sagt, was einen erwartet.
///
/// Auf der Startseite waren das sieben gleich aussehende Kacheln in einer
/// Querleiste — man musste raten, was sich hinter „Zuordnen" verbirgt.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final Speaker speaker = SpeechScope.of(context);
    final int due = state.dueCount;

    return Scaffold(
      // Das Fach im Titel: Wer hier landet, soll ohne Nachdenken wissen,
      // woraus die Übungen kommen.
      appBar: AppBar(title: Text('Üben · ${state.subject.label}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Insets.lg, Insets.sm, Insets.lg, Insets.xxl),
        children: <Widget>[
          if (due > 0) ...<Widget>[
            _DueBanner(due: due),
            const SizedBox(height: Insets.lg),
          ],
          const _SectionTitle('Übungen'),
          _PracticeCard(
            icon: Icons.play_arrow_rounded,
            title: 'Kurzrunde',
            subtitle: 'Mehrere Übungsarten, etwa zwei Minuten',
            onTap: () => _open(context, const SessionScreen()),
          ),
          // Jede Übung ist eine Portion, kein Marathon: Fällige und schwache
          // Karten zuerst, dann ist Schluss. Wer mehr will, fängt neu an —
          // das ist der Unterschied zwischen „geschafft" und „abgebrochen".
          _PracticeCard(
            icon: Icons.style_outlined,
            title: 'Karteikarten',
            subtitle: '${state.dosePerRound} Karten für heute',
            onTap: () => _open(
                context, const FlashcardScreen(title: 'Tagesportion')),
          ),
          _PracticeCard(
            icon: Icons.quiz_outlined,
            title: 'Quiz',
            subtitle: '$kQuestionsPerRound Fragen, vier Antworten je Frage',
            onTap: () =>
                _open(context, const QuizScreen(title: 'Tagesrunde')),
          ),
          _PracticeCard(
            icon: Icons.compare_arrows,
            title: 'Zuordnen',
            subtitle: 'Paare finden, gegen die Zeit im Kopf',
            onTap: () =>
                _open(context, const MatchingScreen(title: 'Tagesrunde')),
          ),
          _PracticeCard(
            icon: Icons.grid_view,
            title: 'Wort bauen',
            subtitle: 'Das Wort aus seinen Buchstaben zusammensetzen',
            onTap: () =>
                _open(context, const BuildWordScreen(title: 'Tagesrunde')),
          ),
          _PracticeCard(
            icon: Icons.keyboard_alt_outlined,
            title: 'Tippen',
            subtitle: 'Die Antwort selbst schreiben — die härteste Übung',
            onTap: () =>
                _open(context, const TypingScreen(title: 'Tagesrunde')),
          ),
          if (speaker.isAvailable)
            _PracticeCard(
              icon: Icons.hearing,
              title: 'Hören',
              subtitle: 'Das gesprochene Wort erkennen',
              onTap: () => _open(
                context,
                const QuizScreen(
                  title: 'Hörübung',
                  direction: QuizDirection.listening,
                ),
              ),
            ),
          const SizedBox(height: Insets.xl),
          const _SectionTitle('Nachschlagen'),
          _PracticeCard(
            icon: Icons.abc,
            title: 'Alphabet & Zeichen',
            subtitle: '28 Buchstaben und die Tashkīl-Zeichen',
            onTap: () => _open(context, const AlphabetScreen()),
          ),
          _PracticeCard(
            icon: Icons.table_chart_outlined,
            title: 'Verben beugen',
            subtitle: 'Acht Verben in allen Personen',
            onTap: () => _open(context, const VerbsScreen()),
          ),
          _PracticeCard(
            icon: Icons.menu_book_outlined,
            title: 'Quran-Sprache',
            subtitle: 'Kurze Suren, häufigste Wörter, Wurzeln',
            onTap: () => _open(context, const QuranScreen()),
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Insets.xs, bottom: Insets.sm),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  const _DueBanner({required this.due});

  final int due;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: Insets.card,
        child: Row(
          children: <Widget>[
            Icon(Icons.notifications_active_outlined,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                '$due ${due == 1 ? "Wort wartet" : "Wörter warten"} auf eine '
                'Wiederholung.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg, vertical: Insets.md),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: Radii.chipShape,
                  ),
                  child: Icon(icon,
                      color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
