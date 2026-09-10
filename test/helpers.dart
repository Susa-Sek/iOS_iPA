import 'dart:io';

import 'package:flutter/material.dart';

import 'package:ipa_testing_github_action/state/custom_cards.dart';
import 'package:ipa_testing_github_action/state/daily_feed.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/reminders.dart';
import 'package:ipa_testing_github_action/state/speech.dart';
import 'package:ipa_testing_github_action/widgets/speak_button.dart';

/// A speech engine for tests: it records instead of speaking.
class FakeSpeechBackend implements SpeechBackend {
  FakeSpeechBackend({this.hasVoice = true});

  final bool hasVoice;
  final List<String> spoken = <String>[];
  final List<String> languages = <String>[];

  @override
  Future<bool> prepare(String language) async => hasVoice;

  @override
  Future<void> setLanguage(String language) async => languages.add(language);

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

/// Erinnerungen für Tests: plant nichts, merkt sich nur.
class FakeReminderBackend implements ReminderBackend {
  final List<PlannedReminder> scheduled = <PlannedReminder>[];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(PlannedReminder reminder) async =>
      scheduled.add(reminder);

  @override
  Future<void> cancelAll() async => scheduled.clear();
}

/// Ein Netz, das nichts hergibt — der Regelfall im Test.
class OfflineFeedBackend implements FeedBackend {
  final List<Uri> calls = <Uri>[];

  @override
  Future<FeedResponse> get(Uri url) async {
    calls.add(url);
    return const FeedResponse.offline();
  }
}

/// Ein Netz, das immer dieselbe Antwort gibt.
class CannedFeedBackend implements FeedBackend {
  CannedFeedBackend(this.wikipedia, this.news);

  final String wikipedia;
  final String news;

  @override
  Future<FeedResponse> get(Uri url) async => FeedResponse(
      200, url.host == DailyFeedService.wikipediaHost ? wikipedia : news);
}

/// Ein Dienst mit den echten, abgelegten Antworten — geladen über denselben
/// Weg wie im Betrieb, nur ohne Netz.
Future<DailyFeedService> loadedFeed({DateTime? day}) async {
  final DailyFeedService service = DailyFeedService(
    backend: CannedFeedBackend(
      File('test/data/wikipedia_feed.json').readAsStringSync(),
      File('test/data/tagesschau_news.json').readAsStringSync(),
    ),
    clock: () => day ?? DateTime(2026, 9, 10, 9),
  );
  await service.refresh();
  return service;
}

/// Wraps a screen in the scopes the app provides at the top level.
Widget wrapScreen(
  Widget child, {
  LearningState? state,
  Speaker? speaker,
  ReminderService? reminders,
  DailyFeedService? feed,
  CustomCardStore? cards,
}) =>
    LearningScope(
      state: state ?? LearningState(),
      child: CustomCardScope(
        store: cards ?? CustomCardStore(),
        child: DailyFeedScope(
          service: feed ?? DailyFeedService(backend: OfflineFeedBackend()),
          child: SpeechScope(
            speaker: speaker ?? Speaker(backend: FakeSpeechBackend()),
            child: ReminderScope(
              service: reminders ??
                  ReminderService(backend: FakeReminderBackend()),
              child: MaterialApp(home: child),
            ),
          ),
        ),
      ),
    );

/// Wie [wrapScreen], aber mit vergrößerter Schrift.
///
/// Wer die Systemschrift hochstellt — und das tun viele —, bekommt jeden Text
/// größer. Layouts, die auf die Standardgröße gebaut sind, brechen dann. Der
/// Test deckt das auf, bevor es ein Nutzer tut.
Widget wrapScreenScaled(
  Widget child, {
  double scale = 1.5,
  LearningState? state,
  Speaker? speaker,
  ReminderService? reminders,
  DailyFeedService? feed,
  CustomCardStore? cards,
}) =>
    LearningScope(
      state: state ?? LearningState(),
      child: CustomCardScope(
        store: cards ?? CustomCardStore(),
        child: DailyFeedScope(
          service: feed ?? DailyFeedService(backend: OfflineFeedBackend()),
          child: SpeechScope(
            speaker: speaker ?? Speaker(backend: FakeSpeechBackend()),
            child: ReminderScope(
              service: reminders ??
                  ReminderService(backend: FakeReminderBackend()),
              child: MaterialApp(
                builder: (BuildContext context, Widget? widget) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: widget!,
                ),
                home: child,
              ),
            ),
          ),
        ),
      ),
    );
