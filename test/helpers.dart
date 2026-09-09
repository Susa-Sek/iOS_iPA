import 'package:flutter/material.dart';

import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/speech.dart';
import 'package:ipa_testing_github_action/widgets/speak_button.dart';

/// A speech engine for tests: it records instead of speaking.
class FakeSpeechBackend implements SpeechBackend {
  FakeSpeechBackend({this.hasVoice = true});

  final bool hasVoice;
  final List<String> spoken = <String>[];

  @override
  Future<bool> prepare(String language) async => hasVoice;

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

/// Wraps a screen in the two scopes the app provides at the top level.
Widget wrapScreen(
  Widget child, {
  LearningState? state,
  Speaker? speaker,
}) =>
    LearningScope(
      state: state ?? LearningState(),
      child: SpeechScope(
        speaker: speaker ?? Speaker(backend: FakeSpeechBackend()),
        child: MaterialApp(home: child),
      ),
    );
