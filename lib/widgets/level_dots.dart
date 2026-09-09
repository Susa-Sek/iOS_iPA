import 'package:flutter/material.dart';

import '../state/learning_state.dart';

/// Shows how safely a word sits: one filled dot per Leitner box.
class LevelDots extends StatelessWidget {
  const LevelDots({
    super.key,
    required this.box,
    this.color,
    this.softColor,
    this.size = 8,
  });

  final int box;
  final Color? color;
  final Color? softColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color active = color ?? theme.colorScheme.primary;
    final Color inactive = softColor ?? theme.dividerColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= LearningState.maxBox; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= box ? active : inactive,
              ),
            ),
          ),
      ],
    );
  }
}
