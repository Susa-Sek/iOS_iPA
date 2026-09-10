import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Kurze Rückmeldung auf eine Antwort — spürbar und sichtbar.
///
/// Ein Lernprogramm lebt davon, dass man sofort weiß, ob es gestimmt hat.
/// Farbe allein reicht dafür nicht: Sie hilft nicht im Dunkeln, nicht bei
/// Farbenblindheit und nicht, wenn man nebenbei hinschaut. Deshalb kommen
/// ein Zeichen und ein kurzer Impuls dazu.
abstract final class AnswerFeedback {
  /// Ein leichter Impuls bei richtig, ein deutlicherer bei falsch.
  static Future<void> tap({required bool correct}) async {
    try {
      if (correct) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Geräte ohne Vibration sind kein Fehlerfall.
    }
  }

  /// Das Zeichen zur Farbe, damit die Rückmeldung nicht nur farbig ist.
  static IconData icon({required bool correct}) =>
      correct ? Icons.check_circle : Icons.cancel;

  static String label({required bool correct}) =>
      correct ? 'Richtig' : 'Falsch';
}

/// Blendet die Erklärung nach der Antwort sanft ein.
class RevealBox extends StatelessWidget {
  const RevealBox({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.normal,
      switchInCurve: Motion.enter,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: child),
      ),
      child: visible ? child : const SizedBox.shrink(),
    );
  }
}
