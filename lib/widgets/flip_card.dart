import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Eine Karte, die sich beim Aufdecken dreht.
///
/// Ohne Bewegung wechselt der Inhalt hart, und man verliert kurz den Faden,
/// ob man gerade die Vorder- oder die Rückseite sieht. Die halbe Drehung
/// beantwortet das ohne ein Wort.
class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.showBack,
    required this.front,
    required this.back,
  });

  final bool showBack;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: showBack ? 1 : 0),
      duration: Motion.normal,
      curve: Motion.enter,
      builder: (BuildContext context, double value, _) {
        // Bis zur Hälfte die Vorderseite, danach die gespiegelte Rückseite.
        final bool showingBack = value >= 0.5;
        final double angle = value * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: showingBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: back,
                )
              : front,
        );
      },
    );
  }
}
