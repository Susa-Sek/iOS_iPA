import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'word_progress.dart';

/// Eine veröffentlichte Version auf GitHub.
@immutable
class Release {
  const Release({
    required this.version,
    required this.apkUrl,
    required this.pageUrl,
  });

  /// Ohne führendes „v": „3.9.0".
  final String version;

  /// Die vollständige APK.
  final String apkUrl;

  /// Die Seite der Version — der Rückfall, wenn kein APK angehängt ist.
  final String pageUrl;

  @override
  String toString() => 'Release $version';
}

/// Woher die neueste Version kommt. Hinter einer Schnittstelle, damit der
/// Test ohne Netz auskommt — dasselbe Muster wie bei [FeedBackend] und
/// [ShareBackend].
abstract class UpdateBackend {
  /// Die neueste Version, oder `null`, wenn sie sich nicht ermitteln lässt.
  Future<Release?> latest();
}

/// Die echte Umsetzung: `…/releases/latest` von GitHub.
///
/// Setzt voraus, dass das Repository **öffentlich** ist. Bei einem privaten
/// bräuchte die App einen Token im Programmcode, und ein Token, der in einer
/// 57-MB-APK mitreist, ist keiner. Antwortet GitHub mit 404, ist genau das
/// der Fall — die App sagt dann nichts, statt einen Fehler zu zeigen.
class GithubReleaseBackend implements UpdateBackend {
  GithubReleaseBackend({
    this.owner = 'Susa-Sek',
    this.repo = 'iOS_iPA',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String owner;
  final String repo;
  final http.Client _client;

  @override
  Future<Release?> latest() async {
    try {
      final http.Response antwort = await _client.get(
        Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest'),
        headers: const <String, String>{
          'Accept': 'application/vnd.github+json',
        },
      ).timeout(const Duration(seconds: 10));
      if (antwort.statusCode != 200) return null;
      return releaseFromJson(
          jsonDecode(utf8.decode(antwort.bodyBytes)) as Map<String, dynamic>);
    } catch (error) {
      debugPrint('Versionsabfrage fehlgeschlagen: $error');
      return null;
    }
  }
}

/// Die Antwort von GitHub in ein [Release] — rein, damit ein Test sie mit
/// einer gespeicherten Antwort prüfen kann.
Release? releaseFromJson(Map<String, dynamic> json) {
  final String tag = (json['tag_name'] as String?) ?? '';
  final String version = tag.startsWith('v') ? tag.substring(1) : tag;
  if (version.isEmpty) return null;

  String? apk;
  final Object? assets = json['assets'];
  if (assets is List) {
    for (final Object? asset in assets) {
      if (asset is! Map) continue;
      final String name = (asset['name'] as String?) ?? '';
      final String url = (asset['browser_download_url'] as String?) ?? '';
      if (name.toLowerCase().endsWith('.apk') && url.isNotEmpty) {
        apk = url;
        break;
      }
    }
  }
  final String seite = (json['html_url'] as String?) ?? '';
  if (apk == null && seite.isEmpty) return null;
  return Release(version: version, apkUrl: apk ?? seite, pageUrl: seite);
}

/// Ist [veroeffentlicht] neuer als [laufend]?
///
/// **Warum das eine eigene Funktion mit eigenem Test ist.** Der Vergleich
/// zweier Versionen ist die Stelle, an der jeder einmal danebengreift:
/// Zeichenweise verglichen ist „3.10.0" **kleiner** als „3.9.0", weil „1"
/// vor „9" kommt. Verglichen wird deshalb Zahl für Zahl.
///
/// Alles, was keine Zahlen enthält, gilt als „nichts Neues": Lieber kein
/// Hinweis als ein falscher.
bool istNeuer(String laufend, String veroeffentlicht) {
  final List<int> a = _teile(laufend);
  final List<int> b = _teile(veroeffentlicht);
  if (a.isEmpty || b.isEmpty) return false;
  for (int i = 0; i < 3; i++) {
    final int links = i < a.length ? a[i] : 0;
    final int rechts = i < b.length ? b[i] : 0;
    if (rechts != links) return rechts > links;
  }
  return false;
}

/// „v3.9.0+20" → [3, 9, 0]. Der Baustand hinter dem `+` zählt nicht mit; er
/// steht in jeder Version und sagt über „neuer" nichts aus, was die drei
/// Zahlen davor nicht schon sagen.
List<int> _teile(String version) {
  final String kern = version.trim().split('+').first.replaceFirst('v', '');
  final List<int> zahlen = <int>[];
  for (final String stueck in kern.split('.')) {
    final int? n = int.tryParse(stueck.trim());
    if (n == null) break;
    zahlen.add(n);
  }
  return zahlen;
}

/// Prüft höchstens einmal am Tag, ob eine neuere Version vorliegt.
class UpdateService extends ChangeNotifier {
  UpdateService({
    UpdateBackend? backend,
    SharedPreferences? preferences,
    DateTime Function()? clock,
    Future<bool> Function(Uri)? opener,
  })  : _backend = backend ?? GithubReleaseBackend(),
        _prefs = preferences,
        _now = clock ?? DateTime.now,
        _opener = opener ?? _oeffneImBrowser;

  /// Nicht umbenennen — siehe test/naming_test.dart.
  static const String checkedKey = 'arabisch_lernen.update.checked';

  final UpdateBackend _backend;
  final DateTime Function() _now;
  final Future<bool> Function(Uri) _opener;
  SharedPreferences? _prefs;

  Release? _neuere;
  int _abfragen = 0;

  /// Die neuere Version, wenn es eine gibt.
  Release? get neuere => _neuere;

  /// Wie oft das Backend wirklich gefragt wurde — für den Test der Bremse.
  @visibleForTesting
  int get abfragen => _abfragen;

  /// Fragt nach, wenn heute noch nicht gefragt wurde.
  ///
  /// Bei jedem Start zu fragen wäre Datenverkehr ohne Gegenwert: Eine neue
  /// Version erscheint alle paar Wochen, nicht alle paar Minuten.
  Future<void> check({required String laufendeVersion, bool force = false}) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('Update-Einstellungen nicht lesbar: $error');
    }
    final String heute = dayKey(_now());
    if (!force && _prefs?.getString(checkedKey) == heute) return;

    _abfragen++;
    final Release? gefunden = await _backend.latest();
    await _prefs?.setString(checkedKey, heute);
    if (gefunden == null) return;

    final Release? vorher = _neuere;
    _neuere = istNeuer(laufendeVersion, gefunden.version) ? gefunden : null;
    if (_neuere?.version != vorher?.version) notifyListeners();
  }

  /// Öffnet die APK-Adresse. Android lädt sie herunter; ein Tipp auf die
  /// fertige Datei installiert sie über die vorhandene App.
  Future<bool> holen() async {
    final Release? r = _neuere;
    if (r == null) return false;
    try {
      return await _opener(Uri.parse(r.apkUrl));
    } catch (error) {
      debugPrint('Adresse ließ sich nicht öffnen: $error');
      return false;
    }
  }

  static Future<bool> _oeffneImBrowser(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Macht den [UpdateService] im Widget-Baum verfügbar.
class UpdateScope extends InheritedNotifier<UpdateService> {
  const UpdateScope({
    super.key,
    required UpdateService service,
    required super.child,
  }) : super(notifier: service);

  /// `null`, wenn kein Scope da ist — die Startseite soll in Tests ohne
  /// Update-Dienst laufen, statt mit einer Zusicherung umzufallen.
  static UpdateService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UpdateScope>()?.notifier;
}
