import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Wie ein Text das Gerät verlässt.
///
/// Eine Schnittstelle wie `SpeechBackend` und `ReminderBackend`, aus
/// demselben Grund: Das Teilen-Blatt gehört dem Betriebssystem, lässt sich
/// im Test nicht öffnen — und im Test soll trotzdem prüfbar sein, **was**
/// verschickt worden wäre.
abstract class ShareBackend {
  /// Gibt zurück, ob das Blatt aufging.
  Future<bool> share(String text, {String? subject});

  Future<void> copy(String text);
}

/// Die echte Umsetzung: das Teilen-Blatt des Systems.
class SystemShareBackend implements ShareBackend {
  const SystemShareBackend();

  @override
  Future<bool> share(String text, {String? subject}) async {
    try {
      final ShareResult ergebnis = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
      return ergebnis.status != ShareResultStatus.unavailable;
    } catch (error) {
      // Auf einem Gerät ohne Teilen-Ziel oder bei einer Plattform, die es
      // nicht kennt, ist das kein Fehler — dann geht der Text in die
      // Zwischenablage, und der Bildschirm sagt das.
      debugPrint('Teilen nicht möglich: $error');
      return false;
    }
  }

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}

/// Verschickt einen Text und sagt, auf welchem Weg.
///
/// Der **Rückfall auf die Zwischenablage** ist kein Notnagel, sondern der
/// Grund, warum das hier eine eigene Klasse ist: Ein Code, der nirgends
/// ankommt, ist schlimmer als einer, den man selbst einfügen muss.
class Sharer {
  Sharer({ShareBackend? backend})
      : _backend = backend ?? const SystemShareBackend();

  final ShareBackend _backend;

  /// Was passiert ist — der Bildschirm meldet es weiter.
  Future<ShareOutcome> send(String text, {String? subject}) async {
    if (await _backend.share(text, subject: subject)) {
      return ShareOutcome.shared;
    }
    await _backend.copy(text);
    return ShareOutcome.copied;
  }

  /// Nur in die Zwischenablage, ohne Blatt.
  Future<void> copy(String text) => _backend.copy(text);
}

enum ShareOutcome {
  shared,
  copied;

  String get message => switch (this) {
        ShareOutcome.shared => 'Verschickt.',
        ShareOutcome.copied => 'In die Zwischenablage gelegt — jetzt einfügen.',
      };
}

/// Macht den Versand im Baum verfügbar.
class ShareScope extends InheritedWidget {
  const ShareScope({super.key, required this.sharer, required super.child});

  final Sharer sharer;

  static Sharer of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShareScope>()?.sharer ??
      Sharer();

  @override
  bool updateShouldNotify(ShareScope oldWidget) => oldWidget.sharer != sharer;
}
