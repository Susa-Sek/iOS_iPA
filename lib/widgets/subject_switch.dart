import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../state/learning_state.dart';
import '../theme/app_theme.dart';

/// Die Leiste, mit der zwischen Arabisch und Wissen gewechselt wird.
///
/// Der **nicht** gewählte Knopf trägt die Zahl seiner offenen
/// Wiederholungen. Ohne „Alles" verschwände die Arbeit im anderen Fach sonst
/// lautlos — eines Tages wären zweihundert Vokabeln überfällig, ohne dass es
/// irgendwo stünde.
///
/// Gezählt werden nur **angefangene** Wörter, deren Termin gekommen ist. Ein
/// nie angesehenes Wort gilt zwar auch als fällig, wäre hier aber eine Zahl,
/// die sich nie ändert.
class SubjectSwitch extends StatelessWidget {
  const SubjectSwitch({super.key});

  /// Höhe der Leiste bei normaler Schriftgröße: Tippfläche plus Luft.
  static const double height = kMinTapTarget + Insets.sm * 2;

  /// Wie hoch die Leiste bei einer bestimmten Schriftgröße sein muss.
  ///
  /// Ein angehefteter Kopf muss seine Höhe **vorher** nennen; malt der Inhalt
  /// weniger, beschwert sich das Layout („layoutExtent exceeds paintExtent").
  /// Deshalb wird hier gerechnet und der Inhalt anschließend auf genau diese
  /// Höhe gezogen.
  static double heightFor(double scale) =>
      Insets.sm * 2 + math.max(kMinTapTarget, 40 * scale);

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final List<Subject> faecher = <Subject>[
      for (final Subject s in Subject.values)
        if (state.hasContent(s)) s,
    ];
    // Ein einziges Fach braucht keinen Umschalter.
    if (faecher.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.lg, Insets.sm, Insets.lg, Insets.sm),
      child: Row(
        // Die Knöpfe füllen die Höhe der Leiste aus, statt sie zu unterbieten.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Subject subject in faecher) ...<Widget>[
            if (subject != faecher.first)
              const SizedBox(width: Insets.sm),
            Expanded(
              child: _SubjectButton(
                subject: subject,
                selected: state.subject == subject,
                due: state.repetitionsDueIn(subject),
                onTap: () => state.setSubject(subject),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectButton extends StatelessWidget {
  const _SubjectButton({
    required this.subject,
    required this.selected,
    required this.due,
    required this.onTap,
  });

  final Subject subject;
  final bool selected;
  final int due;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color vorne = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: Radii.chipShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.chipShape,
        child: Semantics(
          selected: selected,
          button: true,
          label: due > 0
              ? '${subject.label}, $due fällig'
              : subject.label,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md, vertical: Insets.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(selected ? subject.selectedIcon : subject.icon,
                      size: 18, color: vorne),
                  const SizedBox(width: Insets.sm),
                  Flexible(
                    child: Text(
                      subject.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: vorne,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  // Die Zahl steht nur am nicht gewählten Fach: Im aktiven
                  // Fach zeigt die Tageskarte darunter dieselbe Zahl schon
                  // größer.
                  if (!selected && due > 0) ...<Widget>[
                    const SizedBox(width: Insets.sm),
                    _DueMark(due: due),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DueMark extends StatelessWidget {
  const _DueMark({required this.due});

  final int due;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        due > 99 ? '99+' : '$due',
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onError),
      ),
    );
  }
}

/// Hält die Leiste beim Scrollen des Lernwegs am oberen Rand fest.
///
/// Der Fachwechsel ist der häufigste Griff auf dieser Seite; er darf nicht
/// weggescrollt werden. Die Höhe folgt der Schriftgröße des Systems, sonst
/// schneidet die Leiste bei großer Schrift ab.
class SubjectSwitchHeader extends SliverPersistentHeaderDelegate {
  const SubjectSwitchHeader(this.scale);

  final double scale;

  double get _height => SubjectSwitch.heightFor(scale);

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: _height,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        elevation: overlapsContent ? 1 : 0,
        child: const SubjectSwitch(),
      ),
    );
  }

  @override
  bool shouldRebuild(SubjectSwitchHeader oldDelegate) =>
      oldDelegate.scale != scale;
}
