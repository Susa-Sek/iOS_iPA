import 'package:flutter/material.dart';

import '../state/learning_state.dart';
import '../state/sharing.dart';

/// Der Knopf, mit dem man ein Ergebnis weitergibt.
///
/// **Was drinsteht und was nicht.** Ergebnis, Serie, Level — mehr nicht.
/// Kein Name, keine Kennung, nichts über das Gerät. Der Text steht vor dem
/// Verschicken im Teilen-Blatt, man sieht also selbst, was hinausgeht; und
/// er geht nirgendwo hin, außer wohin man ihn schickt.
class ShareResultButton extends StatelessWidget {
  const ShareResultButton({
    super.key,
    required this.was,
    this.richtig,
    this.gesamt,
  });

  /// Woher das Ergebnis kommt: „Quiz", „Lektion", „Kurzrunde", ein Thema.
  final String was;

  /// Das Ergebnis, falls es eines gibt. Bei einer Lektion ohne Fragen nicht.
  final int? richtig;
  final int? gesamt;

  String _text(LearningState state) {
    final StringBuffer out = StringBuffer('Täglich Klüger · $was');
    if (richtig != null && gesamt != null && gesamt! > 0) {
      out.write('\n$richtig von $gesamt richtig');
    }
    if (state.dayStreak > 0) {
      out.write('\n${state.dayStreak} Tage in Folge · Level ${state.level}');
    } else {
      out.write('\nLevel ${state.level}');
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    return TextButton.icon(
      icon: const Icon(Icons.ios_share, size: 18),
      label: const Text('Ergebnis teilen'),
      onPressed: () async {
        final ScaffoldMessengerState melder = ScaffoldMessenger.of(context);
        final ShareOutcome wie =
            await ShareScope.of(context).send(_text(state));
        melder
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(wie.message)));
      },
    );
  }
}
