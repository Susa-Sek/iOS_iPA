import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Die Karte, die kommt, wenn die Tagesportion aufgebraucht ist.
///
/// **Warum es sie gibt.** Der Feed war die einzige Stelle der App ohne
/// Grenze: Am Ende eines Themas stand „Nochmal" als größter Knopf, und Themen
/// ließen sich endlos aneinanderreihen. Das ist das Muster, das Menschen
/// abends um eins noch am Telefon hält — und das Gegenteil dessen, wofür
/// diese App gebaut ist.
///
/// Sie sperrt nicht, sie hält an. Der Unterschied steckt in der Gewichtung:
/// „Fertig" ist der Knopf, „Trotzdem weiter" nur eine Zeile darunter. Eine
/// Mauer wäre bevormundend — wer wirklich zehn Minuten Zeit hat, soll lernen
/// dürfen. Aber es soll eine Entscheidung sein und kein Reflex.
class PortionDone extends StatelessWidget {
  const PortionDone({
    super.key,
    required this.gesehen,
    required this.portion,
    required this.onFertig,
    required this.onTrotzdem,
  });

  /// Wie viele Karten heute schon durchgegangen sind.
  final int gesehen;

  /// Wie groß die Tagesportion ist.
  final int portion;

  final VoidCallback onFertig;
  final VoidCallback onTrotzdem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Schließen',
          onPressed: onFertig,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: Insets.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: Insets.xxl),
                    Icon(Icons.check_circle_outline,
                        size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: Insets.lg),
                    Text('Das war deine Portion',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: Insets.md),
                    Text(
                      '$gesehen Karten heute. Morgen geht es weiter.',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: Insets.sm),
                    Text(
                      'Die Portion wächst mit deinem Tagesziel — wer sich '
                      'mehr vornimmt, bekommt mehr.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: Insets.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  FilledButton(
                      onPressed: onFertig, child: const Text('Fertig')),
                  const SizedBox(height: Insets.xs),
                  // Bewusst kein Knopf: Es soll möglich sein, aber nicht
                  // einladend.
                  TextButton(
                    onPressed: onTrotzdem,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    child: const Text('Trotzdem weiter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
