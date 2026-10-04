import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'progress_store.dart';
import 'word_progress.dart';

/// Kennzeichen der Datei. Eine fremde JSON-Datei soll nicht versehentlich
/// als Lernstand durchgehen.
const String kBackupMarker = 'taeglich-klueger';

/// Format der Sicherungsdatei. Steigt erst, wenn sich die Form ändert —
/// nicht bei jedem neuen Feld: Das verträgt [StoredProgress] von allein,
/// weil dort jedes Feld eine Vorgabe hat.
const int kBackupFormat = 1;

/// Wie eine Sicherung das Gerät verlässt und zurückkommt.
///
/// Eine Schnittstelle aus demselben Grund wie [ShareBackend]: Teilen-Blatt
/// und Dateiauswahl gehören dem Betriebssystem und lassen sich im Test nicht
/// öffnen — **was** geschrieben würde, soll trotzdem prüfbar sein.
abstract class BackupBackend {
  /// Gibt die Sicherung heraus. `false`, wenn kein Ziel zur Verfügung stand.
  Future<bool> write(String dateiname, String inhalt);

  /// Lässt eine Datei auswählen und gibt ihren Inhalt zurück.
  /// `null` heißt abgebrochen.
  Future<String?> read();
}

/// Die echte Umsetzung: Teilen-Blatt zum Sichern, Dateiauswahl zum Lesen.
class FileBackupBackend implements BackupBackend {
  const FileBackupBackend();

  @override
  Future<bool> write(String dateiname, String inhalt) async {
    try {
      final ShareResult ergebnis = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              utf8.encode(inhalt),
              name: dateiname,
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: <String>[dateiname],
          subject: 'Täglich Klüger — Lernstand',
        ),
      );
      return ergebnis.status != ShareResultStatus.unavailable;
    } catch (error) {
      debugPrint('Sicherung konnte nicht herausgegeben werden: $error');
      return false;
    }
  }

  @override
  Future<String?> read() async {
    try {
      final PlatformFile? datei = await FilePicker.pickFile(
        dialogTitle: 'Sicherung auswählen',
      );
      if (datei == null) return null;
      return utf8.decode(await datei.readAsBytes(), allowMalformed: true);
    } catch (error) {
      debugPrint('Datei konnte nicht gelesen werden: $error');
      return null;
    }
  }
}

/// Der Dateiname einer Sicherung: „taeglich-klueger-2026-10-04.json".
String backupName(DateTime when) => 'taeglich-klueger-${dayKey(when)}.json';

/// Der Inhalt einer Sicherung.
///
/// Der Lernstand selbst kommt unverändert aus [ProgressStore.encode] — das
/// ist bereits das Format, in dem er auf dem Gerät liegt. Hier kommt nur die
/// Hülle darum, damit sich eine fremde Datei erkennen lässt.
String makeBackup(StoredProgress progress, DateTime when) =>
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': kBackupMarker,
      'format': kBackupFormat,
      'saved': when.toIso8601String(),
      'progress': jsonDecode(ProgressStore.encode(progress)),
    });

/// Liest eine Sicherung. `null`, wenn die Datei keine ist.
///
/// Lieber nichts tun als etwas Falsches: Eine Sicherung, die beim Einspielen
/// einen halben Lernstand hinterlässt, wäre schlimmer als gar keine.
StoredProgress? readBackup(String raw) {
  try {
    final Object? json = jsonDecode(raw);
    if (json is! Map) return null;
    if (json['app'] != kBackupMarker) return null;
    final Object? inhalt = json['progress'];
    if (inhalt is! Map) return null;
    return ProgressStore.decode(jsonEncode(inhalt));
  } catch (error) {
    debugPrint('Sicherung nicht lesbar: $error');
    return null;
  }
}

/// Wie eine Wiederherstellung ausgegangen ist.
enum RestoreOutcome {
  eingespielt,
  abgebrochen,
  keineSicherung;

  String get message => switch (this) {
        RestoreOutcome.eingespielt => 'Lernstand eingespielt.',
        RestoreOutcome.abgebrochen => 'Nichts geändert.',
        RestoreOutcome.keineSicherung =>
          'Das ist keine Sicherung von Täglich Klüger — nichts geändert.',
      };
}

/// Sichern und Zurückholen.
class BackupService {
  BackupService({BackupBackend? backend, DateTime Function()? clock})
      : _backend = backend ?? const FileBackupBackend(),
        _now = clock ?? DateTime.now;

  final BackupBackend _backend;
  final DateTime Function() _now;

  Future<bool> sichern(StoredProgress progress) {
    final DateTime jetzt = _now();
    return _backend.write(backupName(jetzt), makeBackup(progress, jetzt));
  }

  /// Liest eine Datei und gibt den Lernstand heraus — **eingespielt wird er
  /// hier nicht.** Das tut der Bildschirm, nachdem er gefragt hat.
  Future<(RestoreOutcome, StoredProgress?)> lesen() async {
    final String? roh = await _backend.read();
    if (roh == null) return (RestoreOutcome.abgebrochen, null);
    final StoredProgress? stand = readBackup(roh);
    if (stand == null) return (RestoreOutcome.keineSicherung, null);
    return (RestoreOutcome.eingespielt, stand);
  }
}

/// Macht die Sicherung im Baum verfügbar.
///
/// Mit Rückfall auf einen eigenen Dienst, wie bei [ShareScope]: Ein Baum
/// ohne Scope soll laufen, nicht umfallen. Im Test steht hier ein Backend
/// ohne Dateisystem.
class BackupScope extends InheritedWidget {
  const BackupScope({super.key, required this.service, required super.child});

  final BackupService service;

  static BackupService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BackupScope>()?.service ??
      BackupService();

  @override
  bool updateShouldNotify(BackupScope oldWidget) =>
      oldWidget.service != service;
}
