import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The part of the text-to-speech engine the app actually uses.
///
/// Kept behind an interface so the speaking logic can be tested without a
/// platform channel — and so a device without an Arabic voice fails softly
/// instead of throwing at the user.
abstract class SpeechBackend {
  Future<bool> prepare(String language);
  Future<void> setLanguage(String language);
  Future<void> setRate(double rate);
  Future<void> speak(String text);
  Future<void> stop();
}

/// The real engine.
class FlutterTtsBackend implements SpeechBackend {
  FlutterTtsBackend([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<bool> prepare(String language) async {
    try {
      final Object? available = await _tts.isLanguageAvailable(language);
      if (available == false) return false;
      await _tts.setLanguage(language);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      return true;
    } catch (error) {
      debugPrint('Sprachausgabe nicht verfügbar: $error');
      return false;
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    try {
      await _tts.setLanguage(language);
    } catch (error) {
      debugPrint('Sprache konnte nicht gesetzt werden: $error');
    }
  }

  @override
  Future<void> setRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate);
    } catch (error) {
      debugPrint('Sprechtempo konnte nicht gesetzt werden: $error');
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (error) {
      debugPrint('Sprachausgabe fehlgeschlagen: $error');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (error) {
      debugPrint('Sprachausgabe konnte nicht gestoppt werden: $error');
    }
  }
}

enum SpeechStatus {
  /// Not asked yet.
  unknown,

  /// An Arabic voice answered — words can be spoken.
  ready,

  /// No Arabic voice on this device; the UI explains how to add one.
  unavailable,
}

/// Speaks Arabic words aloud, at a pace a learner can follow.
class Speaker extends ChangeNotifier {
  Speaker({SpeechBackend? backend, SharedPreferences? preferences})
      : _backend = backend ?? FlutterTtsBackend(),
        _prefs = preferences;

  /// Die Sprache des arabischen Wortschatzes.
  static const String language = 'ar';

  /// Für deutsche Wissenskarten.
  static const String germanLanguage = 'de-DE';
  /// Nicht umbenennen — siehe test/naming_test.dart.
  static const String slowKey = 'arabisch_lernen.speech.slow';

  /// Learner pace vs. normal pace. Arabic TTS at 1.0 is too fast to follow.
  static const double slowRate = 0.35;
  static const double normalRate = 0.5;

  final SpeechBackend _backend;
  SharedPreferences? _prefs;

  SpeechStatus _status = SpeechStatus.unknown;
  bool _slow = true;
  String? _speaking;
  String _current = language;

  /// Welche Sprachen das Gerät beherrscht — einmal gefragt, dann gemerkt.
  final Map<String, bool> _available = <String, bool>{};

  SpeechStatus get status => _status;
  bool get isAvailable => _status == SpeechStatus.ready;
  bool get slow => _slow;

  /// The text currently being spoken, for a "speaking" highlight.
  String? get speaking => _speaking;

  Future<void> init() async {
    _prefs ??= await _safePrefs();
    _slow = _prefs?.getBool(slowKey) ?? true;
    final bool ok = await _backend.prepare(language);
    _available[language] = ok;
    _status = ok ? SpeechStatus.ready : SpeechStatus.unavailable;
    if (ok) await _backend.setRate(_slow ? slowRate : normalRate);
    notifyListeners();
  }

  /// Ob für diese Sprache eine Stimme da ist.
  Future<bool> supports(String code) async {
    final bool? known = _available[code];
    if (known != null) return known;
    final bool ok = await _backend.prepare(code);
    _available[code] = ok;
    return ok;
  }

  Future<SharedPreferences?> _safePrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('Einstellungen nicht lesbar: $error');
      return null;
    }
  }

  Future<void> setSlow(bool value) async {
    _slow = value;
    notifyListeners();
    await _backend.setRate(value ? slowRate : normalRate);
    await _prefs?.setBool(slowKey, value);
  }

  /// Spricht [text]. Ohne passende Stimme passiert nichts, damit jeder
  /// Aufrufer das einfach aufrufen kann.
  ///
  /// [languageCode] bestimmt die Stimme: Arabisch für Vokabeln, Deutsch für
  /// Wissenskarten. Die Sprache wird nur umgestellt, wenn sie wechselt.
  Future<void> speak(String text, {String? languageCode}) async {
    final String code = languageCode ?? language;
    if (text.trim().isEmpty) return;
    if (!await supports(code)) return;

    if (code != _current) {
      await _backend.setLanguage(code);
      await _backend.setRate(_slow ? slowRate : normalRate);
      _current = code;
    }

    _speaking = text;
    notifyListeners();
    await _backend.speak(text);
    _speaking = null;
    notifyListeners();
  }

  Future<void> stop() async {
    _speaking = null;
    notifyListeners();
    await _backend.stop();
  }
}
