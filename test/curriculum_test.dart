import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/curriculum.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';

void main() {
  group('Lernweg', () {
    test('jedes Thema steht in genau einem Bereich', () {
      final List<String> inGroups = <String>[
        for (final CategoryGroup group in kGroups)
          for (final VocabCategory category in group.categories) category.id,
      ];
      final Set<String> all =
          kAllCategories.map((VocabCategory c) => c.id).toSet();

      // Keine Dopplung …
      expect(inGroups.length, inGroups.toSet().length,
          reason: 'ein Thema steht in zwei Bereichen');
      // … und nichts vergessen.
      expect(inGroups.toSet(), all,
          reason: 'Themen ohne Bereich: ${all.difference(inGroups.toSet())}');
    });

    test('jeder Bereich hat Name, Beschreibung und Themen', () {
      final Set<String> ids = <String>{};
      for (final CategoryGroup group in kGroups) {
        expect(ids.add(group.id), isTrue, reason: 'doppelte id: ${group.id}');
        expect(group.name.trim(), isNotEmpty);
        expect(group.description.trim(), isNotEmpty, reason: group.name);
        expect(group.categories, isNotEmpty, reason: group.name);
      }
    });

    test('die Bereiche decken den gesamten Wortschatz ab', () {
      final int inGroups = kGroups.fold<int>(
          0, (int sum, CategoryGroup g) => sum + g.entries.length);
      expect(inGroups, kAllEntries.length);
    });

    test('der Wortschatz ist auf über 700 Wörter gewachsen', () {
      expect(kAllEntries.length, greaterThan(700));
      expect(kAllCategories.length, greaterThan(25));
    });
  });
}
