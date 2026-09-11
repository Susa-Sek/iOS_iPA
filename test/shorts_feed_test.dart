import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/shorts_feed.dart';

typedef _K = VocabEntry;

VocabCategory _thema(List<VocabEntry> entries, {String id = 't_test'}) =>
    VocabCategory(
      id: id,
      name: 'Testthema',
      icon: Icons.public,
      color: const Color(0xFF2E7D8A),
      softColor: const Color(0x242E7D8A),
      script: TextScript.latin,
      entries: entries,
    );

VocabEntry _fakt(int i) => _K.fact('Begriff $i', 'Bedeutung $i',
    explanation: 'Erklärung zu Begriff $i.');

VocabEntry _frage(int i) => _K.question('Was ist Nummer $i?', 'Antwort $i',
    distractors: <String>['Falsch ${i}a', 'Falsch ${i}b', 'Falsch ${i}c'],
    explanation: 'Weil Antwort $i stimmt.');

/// Ein Thema mit abwechselnd Fakt und Frage, wie der echte Bestand.
List<VocabEntry> _gemischt(int fakten, int fragen) => <VocabEntry>[
      for (int i = 0; i < fakten; i++) _fakt(i),
      for (int i = 0; i < fragen; i++) _frage(i),
    ];

List<ShortItem> _feed(VocabCategory category, {int seed = 1}) =>
    buildShorts(category: category, random: Random(seed));

void main() {
  group('Shorts-Feed', () {
    test('beginnt mit einem Fakt', () {
      for (final VocabCategory category in kKnowledgeCategories) {
        final List<ShortItem> feed = _feed(category);
        expect(feed, isNotEmpty, reason: category.name);
        expect(feed.first.kind, ShortKind.fakt, reason: category.name);
      }
    });

    test('jede Karte des Themas kommt genau einmal vor', () {
      for (final VocabCategory category in kKnowledgeCategories) {
        final List<String> ids = <String>[
          for (final ShortItem item in _feed(category)) item.entry.id,
        ];
        expect(ids, hasLength(category.entries.length), reason: category.name);
        expect(ids.toSet(), hasLength(category.entries.length),
            reason: category.name);
        expect(ids.toSet(),
            <String>{for (final VocabEntry e in category.entries) e.id},
            reason: category.name);
      }
    });

    test('bei gleich vielen Fakten wie Fragen wechseln sich beide ab', () {
      final List<ShortItem> feed = _feed(_thema(_gemischt(8, 8)));
      expect(longestQuestionRun(feed), 1);
      for (int i = 0; i < feed.length; i++) {
        expect(feed[i].kind, i.isEven ? ShortKind.fakt : ShortKind.frage);
      }
    });

    test('auch bei mehr Fragen als Fakten bleibt der Lauf kurz', () {
      // Das Thema Geschichte hat 6 Fakten und 9 Fragen — mehr als zwei
      // Fragen am Stück darf das nicht werden, sonst ist es ein Test und
      // kein Feed.
      for (final VocabCategory category in kKnowledgeCategories) {
        expect(longestQuestionRun(_feed(category)), lessThanOrEqualTo(2),
            reason: category.name);
      }
    });

    test('zwischen zwei Fakten steht nie eine Lücke von drei Fragen', () {
      // Die Zusage der Verteilung, gerechnet statt geraten: höchstens
      // aufgerundet so viele Fragen je Fakt, wie es überhaupt gibt.
      for (final VocabCategory category in kKnowledgeCategories) {
        final int fakten = category.entries
            .where((VocabEntry e) => e.question == null)
            .length;
        final int fragen = category.entries.length - fakten;
        expect(longestQuestionRun(_feed(category)),
            lessThanOrEqualTo((fragen + fakten - 1) ~/ fakten),
            reason: category.name);
      }
    });

    test('am Ende bleibt kein Block aus lauter Fragen übrig', () {
      final List<ShortItem> feed = _feed(_thema(_gemischt(6, 9)));
      expect(longestQuestionRun(feed), lessThanOrEqualTo(2));
      // Nicht alle übrigen Fragen hinten dran: Der letzte Fakt steht nicht
      // schon in der ersten Hälfte.
      final int letzterFakt =
          feed.lastIndexWhere((ShortItem i) => i.kind == ShortKind.fakt);
      expect(letzterFakt, greaterThan(feed.length ~/ 2));
    });

    test('Fragen behalten ihre mitgelieferten Ablenker', () {
      for (final VocabCategory category in kKnowledgeCategories) {
        for (final ShortItem item in _feed(category)) {
          if (item.kind != ShortKind.frage) continue;
          expect(item.options, hasLength(4), reason: item.entry.german);
          expect(item.options, contains(item.entry.answer),
              reason: item.entry.german);
          for (final String ablenker in item.entry.distractors) {
            expect(item.options, contains(ablenker),
                reason: '${item.entry.german}: $ablenker');
          }
        }
      }
    });

    test('ein Fakt hat nichts anzutippen', () {
      for (final ShortItem item in _feed(_thema(_gemischt(8, 8)))) {
        if (item.kind != ShortKind.fakt) continue;
        expect(item.options, isEmpty);
        expect(item.question, isNull);
      }
    });

    test('die Reihenfolge des Themas bleibt innerhalb der Art erhalten', () {
      final VocabCategory category = kKnowledgeCategories.first;
      final List<ShortItem> feed = _feed(category);
      for (final ShortKind kind in ShortKind.values) {
        final List<String> imFeed = <String>[
          for (final ShortItem i in feed)
            if (i.kind == kind) i.entry.id,
        ];
        final List<String> imThema = <String>[
          for (final VocabEntry e in category.entries)
            if ((e.question == null) == (kind == ShortKind.fakt)) e.id,
        ];
        expect(imFeed, imThema, reason: kind.name);
      }
    });

    test('leeres und winziges Thema brechen nicht', () {
      expect(_feed(_thema(const <VocabEntry>[])), isEmpty);
      expect(_feed(_thema(<VocabEntry>[_fakt(0)])), hasLength(1));
      final List<ShortItem> nurFragen =
          _feed(_thema(<VocabEntry>[_frage(0), _frage(1)]));
      expect(nurFragen, hasLength(2));
      expect(nurFragen.first.kind, ShortKind.frage);
      expect(_feed(_thema(_gemischt(1, 2))), hasLength(3));
    });

    test('verschiedene Zufallszahlen ändern die Reihenfolge nicht', () {
      final VocabCategory category = kKnowledgeCategories.first;
      final List<String> a = <String>[
        for (final ShortItem i in _feed(category, seed: 1)) i.entry.id,
      ];
      final List<String> b = <String>[
        for (final ShortItem i in _feed(category, seed: 99)) i.entry.id,
      ];
      // Gemischt werden die vier Antworten, nicht der Weg durchs Thema.
      expect(a, b);
    });
  });
}
