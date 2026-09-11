import 'dart:math';

import 'package:flutter/material.dart';

import '../data/achievements_data.dart';
import '../models/achievement.dart';
import '../state/learning_state.dart';
import '../state/reward_store.dart';
import '../theme/app_theme.dart';

/// Zeigt an, wenn etwas freigeschaltet wurde.
///
/// **Warum es das braucht.** Die Abzeichen standen von Anfang an in der App
/// und schalteten sich **lautlos** frei: Wer nicht zufällig in „Erfolge"
/// nachsah, erfuhr nie, dass er eines bekommen hatte. Eine Belohnung, die
/// niemand bemerkt, ist keine.
///
/// Der Wächter sitzt einmal im Gerüst und nicht in jeder Übung — dort
/// entstehen die Abzeichen zwar, aber er müsste dann achtmal eingebaut
/// werden und ginge einmal verloren.
class RewardWatcher extends StatefulWidget {
  const RewardWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<RewardWatcher> createState() => _RewardWatcherState();
}

class _RewardWatcherState extends State<RewardWatcher> {
  bool _zeigtGerade = false;
  bool? _zielVorher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pruefen());
  }

  Future<void> _pruefen() async {
    if (!mounted || _zeigtGerade) return;
    final LearningState state = LearningScope.of(context);
    final RewardStore rewards = RewardScope.of(context);
    if (!state.isLoaded || !rewards.isLoaded) return;

    final AchievementStats stats = state.achievementStats;
    final List<Achievement> offen = <Achievement>[
      for (final Achievement a in kAchievements)
        if (a.isUnlocked(stats) && !rewards.wasAnnounced(a.id)) a,
    ];

    // Erster Start nach dem Update: Wer schon zwölf Abzeichen hat, soll
    // nicht zwölf Meldungen wegtippen müssen. Sie gelten als gesehen.
    if (rewards.isFresh) {
      await rewards.markAnnounced(offen.map((Achievement a) => a.id));
      _zielVorher = state.goalReached;
      return;
    }

    if (offen.isNotEmpty) {
      _zeigtGerade = true;
      // Immer nur eines auf einmal: Zwei Blätter übereinander sind keine
      // Belohnung, sondern eine Sperre.
      final Achievement erstes = offen.first;
      await rewards.markAnnounced(<String>[erstes.id]);
      if (mounted) await _blattZeigen(_AbzeichenInhalt(achievement: erstes));
      _zeigtGerade = false;
      if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => _pruefen());
      return;
    }

    // Das Tagesziel fällt: derselbe Moment, ohne Abzeichen.
    final bool ziel = state.goalReached;
    if (_zielVorher == false && ziel) {
      _zeigtGerade = true;
      await _blattZeigen(_ZielInhalt(streak: state.dayStreak));
      _zeigtGerade = false;
    }
    _zielVorher = ziel;
  }

  Future<void> _blattZeigen(Widget inhalt) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (BuildContext context) => SafeArea(child: inhalt),
      );

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Das Blatt zu einem frisch freigeschalteten Abzeichen.
class _AbzeichenInhalt extends StatelessWidget {
  const _AbzeichenInhalt({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) => _Blatt(
        icon: achievement.icon,
        ueber: 'Abzeichen freigeschaltet',
        titel: achievement.name,
        text: achievement.description,
      );
}

/// Das Blatt, wenn das Tagesziel gefallen ist.
class _ZielInhalt extends StatelessWidget {
  const _ZielInhalt({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) => _Blatt(
        icon: Icons.local_fire_department,
        ueber: 'Tagesziel geschafft',
        titel: streak > 1 ? '$streak Tage in Folge' : 'Heute erledigt',
        text: streak > 1
            ? 'Morgen wieder — dann sind es ${streak + 1}.'
            : 'Das ist der Anfang einer Serie.',
      );
}

class _Blatt extends StatelessWidget {
  const _Blatt({
    required this.icon,
    required this.ueber,
    required this.titel,
    required this.text,
  });

  final IconData icon;
  final String ueber;
  final String titel;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Ein Blatt von unten bekommt nur einen Teil des Schirms. Bei großer
    // Schrift auf einem kleinen Telefon lief der Inhalt unten heraus — und
    // ausgerechnet der Knopf zum Schließen war weg. Der Kranz schrumpft
    // mit, der Rest scrollt.
    final double kranz = MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? 96
        : 132;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, 0, Insets.lg, Insets.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(child: _Funken(icon: icon, groesse: kranz)),
          const SizedBox(height: Insets.lg),
          Text(ueber,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: Insets.xs),
          Text(titel,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: Insets.sm),
          Text(text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Insets.xl),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Weiter so'),
          ),
        ],
      ),
    );
  }
}

/// Ein kurzer Funkenkranz um das Symbol.
///
/// Selbst gemalt statt als Paket geholt: Es sind zwölf Striche auf einem
/// Kreis, und eine Abhängigkeit dafür wäre 300 Kilobyte für zwei Sekunden.
class _Funken extends StatefulWidget {
  const _Funken({required this.icon, this.groesse = 132});

  final IconData icon;
  final double groesse;

  @override
  State<_Funken> createState() => _FunkenState();
}

class _FunkenState extends State<_Funken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double innen = widget.groesse * 0.55;
    return SizedBox(
      width: widget.groesse,
      height: widget.groesse,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) => CustomPaint(
          painter: _FunkenPainter(
            t: Curves.easeOut.transform(_controller.value),
            farbe: theme.colorScheme.primary,
          ),
          child: child,
        ),
        child: Center(
          child: Container(
            width: innen,
            height: innen,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon,
                size: innen / 2,
                color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _FunkenPainter extends CustomPainter {
  _FunkenPainter({required this.t, required this.farbe});

  /// 0 bis 1 — wie weit die Funken geflogen sind.
  final double t;
  final Color farbe;

  static const int anzahl = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final Offset mitte = Offset(size.width / 2, size.height / 2);
    final Paint stift = Paint()
      ..color = farbe.withValues(alpha: (1 - t) * 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double radius = size.shortestSide / 2;
    for (int i = 0; i < anzahl; i++) {
      final double winkel = i * 2 * pi / anzahl;
      final double innen = radius * 0.6 + t * radius * 0.33;
      final double aussen = innen + radius * 0.15 * (1 - t);
      canvas.drawLine(
        mitte + Offset(cos(winkel), sin(winkel)) * innen,
        mitte + Offset(cos(winkel), sin(winkel)) * aussen,
        stift,
      );
    }
  }

  @override
  bool shouldRepaint(_FunkenPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.farbe != farbe;
}
