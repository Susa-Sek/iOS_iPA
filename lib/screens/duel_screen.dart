import 'dart:math';

import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart';

import '../models/subject.dart';
import '../models/vocabulary.dart';
import '../state/duel.dart';
import '../state/duel_store.dart';
import '../state/learning_state.dart';
import '../state/quiz_builder.dart';
import '../state/sharing.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';

/// Ein Duell gegen jemanden, den man kennt — ohne Server und ohne Konto.
///
/// **Wie es ohne Server geht.** Beide Seiten bauen aus **derselben Zahl**
/// dieselbe Runde: dieselben Fragen, in derselben Reihenfolge, mit den
/// Antworten an denselben Stellen. Verschickt wird deshalb nur diese Zahl,
/// als kurzer Code in einer Nachricht. Es gibt nichts anzumelden, nichts
/// hochzuladen, und man sieht selbst, was das Gerät verlässt.
class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) DuelScope.of(context).load();
    });
  }

  /// Alle Themen des gewählten Fachs, in ihrer Reihenfolge.
  List<VocabCategory> _themen(LearningState state) => <VocabCategory>[
        for (final CategoryGroup g in state.groups) ...g.categories,
      ];

  /// Findet das Thema zu einer Kurzsumme — über **beide** Fächer, weil der
  /// Code auch aus dem anderen kommen kann.
  String? _themaZu(LearningState state, int summe) {
    for (final Subject fach in Subject.values) {
      for (final CategoryGroup g in state.groupsOf(fach)) {
        for (final VocabCategory c in g.categories) {
          if (stableHash(c.id) & 0xFFFF == summe) return c.id;
        }
      }
    }
    return null;
  }

  VocabCategory? _themaMit(LearningState state, String id) {
    for (final Subject fach in Subject.values) {
      for (final CategoryGroup g in state.groupsOf(fach)) {
        for (final VocabCategory c in g.categories) {
          if (c.id == id) return c;
        }
      }
    }
    return null;
  }

  // ---- Herausfordern ----------------------------------------------------

  Future<void> _herausfordern() async {
    final LearningState state = LearningScope.of(context);
    final List<VocabCategory> themen = _themen(state);
    if (themen.isEmpty) return;

    final VocabCategory? gewaehlt = await showModalBottomSheet<VocabCategory>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => _ThemenWahl(themen: themen),
    );
    if (gewaehlt == null || !mounted) return;

    final Duel duell = newDuel(
      topicId: gewaehlt.id,
      pool: gewaehlt.entries,
      random: _random,
    );
    await _spielen(duell, gewaehlt, startedByMe: true);
  }

  // ---- Annehmen ---------------------------------------------------------

  Future<void> _annehmen() async {
    final LearningState state = LearningScope.of(context);
    final String? text = await _codeFragen(
      titel: 'Duell annehmen',
      hinweis: 'Die Nachricht hier einfügen',
    );
    if (text == null || !mounted) return;

    final Duel? duell = decodeDuel(
      text,
      topicByHash: (int summe) => _themaZu(state, summe),
    );
    if (duell == null) {
      _sagen('In dem Text steckt kein Duell-Code.');
      return;
    }

    final VocabCategory? thema = _themaMit(state, duell.topicId);
    if (thema == null) {
      _sagen('Das Thema dieses Duells kennt deine App nicht.');
      return;
    }
    // Der Fingerabdruck ist der Grund, warum hier eine Meldung steht und
    // nicht stillschweigend andere Fragen kommen.
    if (fingerprintOf(thema.entries) != duell.fingerprint) {
      _sagen('Ihr habt verschiedene Versionen der App — die Fragen zu '
          '„${thema.name}" sind nicht dieselben.');
      return;
    }
    await _spielen(duell, thema, startedByMe: false);
  }

  // ---- Spielen ----------------------------------------------------------

  Future<void> _spielen(
    Duel duell,
    VocabCategory thema, {
    required bool startedByMe,
  }) async {
    final List<QuizQuestion> runde =
        buildDuelRound(duel: duell, pool: thema.entries);
    int richtig = 0;
    int gesamt = runde.length;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          title: 'Duell · ${thema.name}',
          questions: runde,
          onResult: (int r, int g) {
            richtig = r;
            gesamt = g;
          },
        ),
      ),
    );
    if (!mounted) return;

    final DuelRecord record = DuelRecord(
      code: encodeDuel(duell),
      topicId: duell.topicId,
      duelId: duell.id,
      own: richtig,
      total: gesamt,
      startedByMe: startedByMe,
    );
    await DuelScope.of(context).add(record);
    if (!mounted) return;

    await _teilen(
      startedByMe
          ? 'Duell: ${thema.name}\n'
              'Ich hatte $richtig von $gesamt. Schaffst du mehr?\n\n'
              '${record.code}\n\n'
              'Mit „Täglich Klüger" einfügen — du bekommst genau dieselben '
              'Fragen.'
          : 'Duell: ${thema.name}\n'
              'Ich hatte $richtig von $gesamt.\n\n'
              '${encodeResult(DuelResult(duelId: duell.id, correct: richtig, total: gesamt))}',
    );
  }

  // ---- Ergebnis eintragen ----------------------------------------------

  Future<void> _ergebnisEintragen() async {
    final String? text = await _codeFragen(
      titel: 'Ergebnis eintragen',
      hinweis: 'Die Antwort deines Gegenübers einfügen',
    );
    if (text == null || !mounted) return;

    final DuelResult? ergebnis = decodeResult(text);
    if (ergebnis == null) {
      _sagen('In dem Text steckt kein Ergebnis-Code.');
      return;
    }
    final DuelRecord? record =
        await DuelScope.of(context).applyResult(ergebnis);
    if (!mounted) return;
    if (record == null) {
      _sagen('Zu diesem Ergebnis gibt es hier kein Duell.');
      return;
    }
    _sagen(switch (record.won) {
      true => 'Gewonnen: ${record.own} zu ${record.theirs}.',
      false => 'Verloren: ${record.own} zu ${record.theirs}.',
      null => 'Unentschieden: ${record.own} zu ${record.theirs}.',
    });
  }

  // ---- Kleinkram --------------------------------------------------------

  Future<String?> _codeFragen({
    required String titel,
    required String hinweis,
  }) async {
    // Was in der Zwischenablage liegt, ist fast immer genau der Code —
    // einmal weniger einfügen.
    final ClipboardData? ablage =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return null;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => _CodeDialog(
        titel: titel,
        hinweis: hinweis,
        vorbelegt: ablage?.text ?? '',
      ),
    );
  }

  Future<void> _teilen(String text) async {
    final ShareOutcome wie = await ShareScope.of(context).send(text);
    if (!mounted) return;
    _sagen(wie.message);
  }

  void _sagen(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DuelStore duelle = DuelScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Duell')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Insets.lg, Insets.sm, Insets.lg, Insets.xxl),
        children: <Widget>[
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: Insets.card,
              child: Text(
                'Beide bekommen genau dieselben Fragen. Verschickt wird nur '
                'ein kurzer Code — kein Konto, keine Anmeldung, nichts, was '
                'du nicht selbst sendest.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Weg(
            icon: Icons.sports_kabaddi,
            titel: 'Herausfordern',
            text: 'Thema wählen, selbst spielen, Code verschicken',
            onTap: _herausfordern,
          ),
          _Weg(
            icon: Icons.download_outlined,
            titel: 'Duell annehmen',
            text: 'Code einfügen und dieselben Fragen spielen',
            onTap: _annehmen,
          ),
          _Weg(
            icon: Icons.scoreboard_outlined,
            titel: 'Ergebnis eintragen',
            text: 'Die Antwort deines Gegenübers einfügen',
            onTap: _ergebnisEintragen,
          ),
          if (duelle.records.isNotEmpty) ...<Widget>[
            const SizedBox(height: Insets.xl),
            Text('Bisher',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Insets.sm),
            for (final DuelRecord record in duelle.records)
              _DuellZeile(
                record: record,
                name: _themaMit(LearningScope.of(context), record.topicId)
                        ?.name ??
                    'Thema',
                onTeilen: () => _teilen(record.code),
              ),
          ],
        ],
      ),
    );
  }
}

/// Der Dialog, in den man den Code einfügt.
///
/// Ein eigenes Widget, damit das Eingabefeld seinen Controller **selbst**
/// besitzt. Wird er direkt nach `showDialog` entsorgt, läuft die
/// Ausblendung noch und greift auf ihn zu — das ist kein Randfall, das
/// passiert jedes Mal.
class _CodeDialog extends StatefulWidget {
  const _CodeDialog({
    required this.titel,
    required this.hinweis,
    required this.vorbelegt,
  });

  final String titel;
  final String hinweis;
  final String vorbelegt;

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.vorbelegt);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.titel),
        content: TextField(
          controller: _controller,
          maxLines: 4,
          minLines: 2,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.hinweis,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Weiter'),
          ),
        ],
      );
}

class _Weg extends StatelessWidget {
  const _Weg({
    required this.icon,
    required this.titel,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String titel;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(titel,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(text),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _DuellZeile extends StatelessWidget {
  const _DuellZeile({
    required this.record,
    required this.name,
    required this.onTeilen,
  });

  final DuelRecord record;
  final String name;
  final VoidCallback onTeilen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? farbe = switch (record.won) {
      true => Feedback.right(context),
      false => theme.colorScheme.error,
      null => null,
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        record.complete ? Icons.emoji_events_outlined : Icons.hourglass_empty,
        color: farbe ?? theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(name),
      subtitle: Text(record.complete
          ? 'Du ${record.own} : ${record.theirs} '
              '${record.won == true ? '— gewonnen' : record.won == false ? '— verloren' : '— unentschieden'}'
          : 'Du ${record.own} von ${record.total} · Antwort steht aus'),
      trailing: IconButton(
        icon: const Icon(Icons.ios_share),
        tooltip: 'Code noch einmal verschicken',
        onPressed: onTeilen,
      ),
    );
  }
}

/// Die Themenwahl beim Herausfordern.
class _ThemenWahl extends StatelessWidget {
  const _ThemenWahl({required this.themen});

  final List<VocabCategory> themen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, 0, Insets.lg, Insets.sm),
            child: Text('Worüber?', style: theme.textTheme.titleMedium),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: themen.length,
              itemBuilder: (BuildContext context, int i) => ListTile(
                leading: Icon(themen[i].icon, color: themen[i].color),
                title: Text(themen[i].name),
                subtitle: Text('${themen[i].entries.length} Karten'),
                onTap: () => Navigator.of(context).pop(themen[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
