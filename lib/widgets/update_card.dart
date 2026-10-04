import 'package:flutter/material.dart';

import '../state/update_check.dart';
import '../theme/app_theme.dart';

/// „Version 3.9.0 ist da" — eine ruhige Karte, kein Dialog.
///
/// **Warum kein Dialog.** Ein Update ist nie dringend. Etwas, das sich vor
/// den Bildschirm stellt und weggeklickt werden muss, bevor man lernen kann,
/// wäre an dieser Stelle respektlos. Die Karte steht da und wartet.
///
/// Gibt es nichts Neues — oder keinen Update-Dienst, etwa im Test —, nimmt
/// sie **keinen Platz** ein.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final UpdateService? service = UpdateScope.maybeOf(context);
    final Release? neu = service?.neuere;
    if (service == null || neu == null) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: Row(
            children: <Widget>[
              Icon(Icons.system_update,
                  color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Version ${neu.version} ist da',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      'Dein Lernstand bleibt erhalten.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.sm),
              FilledButton(
                onPressed: () async {
                  final ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  if (!await service.holen()) {
                    messenger.showSnackBar(const SnackBar(
                      content: Text(
                        'Die Adresse ließ sich nicht öffnen. Die Version '
                        'steht auf der GitHub-Seite des Projekts.',
                      ),
                    ));
                  }
                },
                child: const Text('Holen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
