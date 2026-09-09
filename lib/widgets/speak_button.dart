import 'package:flutter/material.dart';

import '../state/speech.dart';

/// Makes the [Speaker] available to the whole widget tree.
class SpeechScope extends InheritedNotifier<Speaker> {
  const SpeechScope({
    super.key,
    required Speaker speaker,
    required super.child,
  }) : super(notifier: speaker);

  static Speaker of(BuildContext context) {
    final SpeechScope? scope =
        context.dependOnInheritedWidgetOfExactType<SpeechScope>();
    assert(scope != null, 'No SpeechScope found in the widget tree');
    return scope!.notifier!;
  }
}

/// A speaker icon that reads an Arabic word aloud.
///
/// If the device has no Arabic voice the button stays visible but explains,
/// on tap, how to install one — that is more useful than a button that
/// silently does nothing.
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.size = 24,
    this.color,
  });

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Speaker speaker = SpeechScope.of(context);
    final bool speaking = speaker.speaking == text;

    return IconButton(
      icon: Icon(speaking ? Icons.volume_up : Icons.volume_up_outlined),
      iconSize: size,
      color: color,
      tooltip: 'Anhören',
      onPressed: () {
        if (speaker.isAvailable) {
          speaker.speak(text);
        } else {
          showMissingVoiceHint(context);
        }
      },
    );
  }

  /// Explains what to install — the app cannot ship a system voice itself.
  static void showMissingVoiceHint(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Keine arabische Stimme'),
        content: const Text(
          'Auf diesem Gerät ist keine arabische Sprachausgabe installiert. '
          'Unter Android findest du sie in den Einstellungen unter '
          '"Sprache & Eingabe" → "Text-in-Sprache-Ausgabe": dort die '
          'Sprachdaten der Google-Sprachausgabe öffnen und Arabisch '
          'herunterladen.\n\n'
          'Danach die App neu starten.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Alles klar'),
          ),
        ],
      ),
    );
  }
}
