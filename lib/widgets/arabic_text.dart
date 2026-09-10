import 'package:flutter/material.dart';

import '../models/vocabulary.dart';

/// Setzt Schrift in der richtigen Leserichtung und Größe.
///
/// Arabisch läuft von rechts nach links und braucht mehr Zeilenhöhe, damit
/// die Zeichen über und unter den Buchstaben Platz haben. Deutsch läuft
/// links herum und in normaler Größe. Die Voreinstellung bleibt arabisch,
/// damit die bestehenden Aufrufer unverändert gültig sind.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.color,
    this.fontWeight = FontWeight.w500,
    this.textAlign,
    this.script = TextScript.arabic,
    this.maxLines,
  });

  /// Für die Antwortseite eines Eintrags: Schrift und Größe richten sich
  /// danach, ob dort ein arabisches Wort oder deutscher Text steht.
  factory ArabicText.answer(
    VocabEntry entry, {
    Key? key,
    double arabicSize = 24,
    double latinSize = 20,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
  }) =>
      ArabicText(
        entry.answer,
        key: key,
        fontSize: entry.isLanguage ? arabicSize : latinSize,
        color: color,
        textAlign: textAlign,
        script: entry.script,
        maxLines: maxLines,
      );

  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final TextScript script;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          script.isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          height: script.isRightToLeft ? 1.6 : 1.35,
          fontWeight: fontWeight,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
