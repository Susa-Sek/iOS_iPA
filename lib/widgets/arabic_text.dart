import 'package:flutter/material.dart';

/// Renders Arabic script right-to-left and a bit larger than the surrounding
/// German text, so the letter shapes stay readable.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.color,
    this.fontWeight = FontWeight.w500,
    this.textAlign,
  });

  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.6,
          fontWeight: fontWeight,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
