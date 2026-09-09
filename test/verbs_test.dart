import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/verbs_data.dart';
import 'package:ipa_testing_github_action/models/arabic.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';

/// Die acht Personen, die jede Tabelle abdecken muss.
const List<String> _persons = <String>[
  'ich', 'du (m.)', 'du (w.)', 'er', 'sie', 'wir', 'ihr', 'sie (Mz.)',
];

void main() {
  group('Verbtabellen', () {
    test('jedes Verb hat alle acht Personen, in fester Reihenfolge', () {
      expect(kVerbs, isNotEmpty);
      for (final Verb verb in kVerbs) {
        expect(verb.forms.map((VerbForm f) => f.person).toList(), _persons,
            reason: verb.german);
      }
    });

    test('alle Formen sind vokalisiert und ausgefüllt', () {
      for (final Verb verb in kVerbs) {
        expect(verb.german.trim(), isNotEmpty);
        expect(hasTashkil(verb.past), isTrue, reason: verb.german);
        expect(hasTashkil(verb.present), isTrue, reason: verb.german);
        for (final VerbForm form in verb.forms) {
          expect(hasTashkil(form.past), isTrue,
              reason: '${verb.german} ${form.person}');
          expect(hasTashkil(form.present), isTrue,
              reason: '${verb.german} ${form.person}');
          expect(form.transliteration.contains('/'), isTrue,
              reason: '${verb.german} ${form.person}');
        }
      }
    });

    test('die 3. Person männlich entspricht der Grundform', () {
      for (final Verb verb in kVerbs) {
        final VerbForm er =
            verb.forms.firstWhere((VerbForm f) => f.person == 'er');
        expect(er.past, verb.past, reason: verb.german);
        expect(er.present, verb.present, reason: verb.german);
      }
    });

    test('die Gegenwart trägt die Personen-Vorsilbe', () {
      for (final Verb verb in kVerbs) {
        for (final VerbForm form in verb.forms) {
          final String first = withoutTashkil(form.present).substring(0, 1);
          final String expected = switch (form.person) {
            // Bei Verben mit Hamza als erstem Wurzelbuchstaben (أَكَلَ) zieht
            // sich die Vorsilbe أَ mit dem أْ zu آ zusammen: آكُلُ.
            'ich' => 'أاآ',
            'wir' => 'ن',
            'er' || 'sie (Mz.)' => 'ي',
            _ => 'ت',
          };
          expect(expected.contains(first), isTrue,
              reason: '${verb.german}, ${form.person}: ${form.present} '
                  'beginnt mit "$first"');
        }
      }
    });
  });
}
