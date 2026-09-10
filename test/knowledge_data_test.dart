import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/content_registry.dart';
import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/typing_check.dart';

/// Ein arabischer Buchstabe. In den Wissensdaten darf keiner vorkommen —
/// das Gegenstück zu `vocabulary_data_test.dart`, das für `kAllEntries`
/// genau das Umgekehrte fordert.
final RegExp _arabisch = RegExp(r'[؀-ۿ]');

void main() {
  group('Wissensdaten', () {
    test('jedes Thema hat genug Einträge für eine Runde', () {
      for (final VocabCategory category in kKnowledgeCategories) {
        expect(category.entries.length, greaterThanOrEqualTo(12),
            reason: category.name);
      }
    });

    test('der Bestand ist groß genug', () {
      expect(kKnowledgeEntries.length, greaterThanOrEqualTo(280));
    });

    test('jedes Thema hat eine eindeutige id und lateinische Schrift', () {
      final Set<String> ids = <String>{};
      for (final VocabCategory category in kKnowledgeCategories) {
        expect(ids.add(category.id), isTrue, reason: 'doppelt: ${category.id}');
        expect(category.isLanguage, isFalse, reason: category.name);
        expect(category.arabicName, isNull, reason: category.name);
      }
    });

    test('kein Feld ist leer', () {
      for (final VocabEntry entry in kKnowledgeEntries) {
        expect(entry.german.trim(), isNotEmpty);
        expect(entry.answer.trim(), isNotEmpty);
        expect(entry.explanation?.trim(), isNotEmpty, reason: entry.german);
      }
    });

    test('kein arabisches Zeichen im Wissen', () {
      for (final VocabEntry entry in kKnowledgeEntries) {
        expect(_arabisch.hasMatch(entry.german), isFalse, reason: entry.german);
        expect(_arabisch.hasMatch(entry.answer), isFalse, reason: entry.german);
      }
    });

    test('jede Frage hat genau drei brauchbare Ablenker', () {
      final Iterable<VocabEntry> fragen =
          kKnowledgeEntries.where((VocabEntry e) => e.question != null);
      expect(fragen, isNotEmpty);

      for (final VocabEntry entry in fragen) {
        expect(entry.distractors, hasLength(3), reason: entry.german);
        expect(entry.distractors, isNot(contains(entry.answer)),
            reason: entry.german);
        expect(entry.distractors.toSet(), hasLength(3),
            reason: 'doppelter Ablenker bei „${entry.german}"');
        for (final String ablenker in entry.distractors) {
          expect(ablenker.trim(), isNotEmpty, reason: entry.german);
        }
      }
    });

    test('kein Ablenker fällt mit der Antwort zusammen', () {
      // Beim Tippen wird nachsichtig verglichen: ohne Groß- und
      // Kleinschreibung, ohne Satzzeichen, ohne Umlautpunkte. Zwei Antworten,
      // die sich nur darin unterscheiden, wären danach dieselbe — und der
      // Ablenker ginge als richtig durch.
      for (final VocabEntry entry in kKnowledgeEntries) {
        final String antwort = normalizeAnswer(entry.answer);
        for (final String ablenker in entry.distractors) {
          expect(normalizeAnswer(ablenker), isNot(antwort),
              reason: '„$ablenker" bei „${entry.german}"');
        }
      }
    });

    test('eine Frage ist als Frage formuliert', () {
      for (final VocabEntry entry in kKnowledgeEntries) {
        if (entry.question == null) continue;
        expect(entry.question, entry.german);
        expect(entry.german, endsWith('?'), reason: entry.german);
      }
    });

    test('eine Begriffskarte bringt keine Ablenker mit', () {
      for (final VocabEntry entry in kKnowledgeEntries) {
        if (entry.question != null) continue;
        expect(entry.distractors, isEmpty, reason: entry.german);
      }
    });

    test('beide Sorten kommen vor', () {
      final int fragen =
          kKnowledgeEntries.where((VocabEntry e) => e.question != null).length;
      // Nur Fragen wäre eine Prüfung, nur Begriffe ein Lexikon.
      expect(fragen, greaterThan(kKnowledgeEntries.length ~/ 4));
      expect(fragen, lessThan(kKnowledgeEntries.length * 3 ~/ 4));
    });

    test('keine id kommt zweimal vor', () {
      // Die id ist der Schlüssel des gespeicherten Lernstands. Zwei Karten
      // mit derselben id teilten sich Lernstufe und Termin.
      final Set<String> ids = <String>{};
      for (final VocabEntry entry in kKnowledgeEntries) {
        expect(ids.add(entry.id), isTrue, reason: 'doppelt: ${entry.id}');
      }
    });

    test('keine id kollidiert mit dem Wortschatz', () {
      final Set<String> wortschatz = <String>{
        for (final VocabEntry e in kAllEntries) e.id,
      };
      for (final VocabEntry entry in kKnowledgeEntries) {
        expect(wortschatz.contains(entry.id), isFalse, reason: entry.id);
      }
    });

    test('innerhalb eines Themas kommt kein Begriff doppelt vor', () {
      for (final VocabCategory category in kKnowledgeCategories) {
        final Set<String> gesehen = <String>{};
        for (final VocabEntry entry in category.entries) {
          expect(gesehen.add(entry.german), isTrue,
              reason: '${category.name}: ${entry.german}');
        }
      }
    });

    test('Antworten bleiben kurz genug für vier Knöpfe', () {
      for (final VocabEntry entry in kKnowledgeEntries) {
        expect(entry.answer.length, lessThanOrEqualTo(60),
            reason: '${entry.german}: ${entry.answer}');
        for (final String ablenker in entry.distractors) {
          expect(ablenker.length, lessThanOrEqualTo(60), reason: ablenker);
        }
      }
    });
  });

  group('Wissenslernweg', () {
    test('jedes Thema steht in genau einem Bereich', () {
      final Map<String, int> vorkommen = <String, int>{};
      for (final CategoryGroup group in kKnowledgeGroups) {
        for (final VocabCategory category in group.categories) {
          vorkommen[category.id] = (vorkommen[category.id] ?? 0) + 1;
        }
      }
      for (final VocabCategory category in kKnowledgeCategories) {
        expect(vorkommen[category.id], 1, reason: category.name);
      }
    });

    test('die Bereiche decken das ganze Wissen ab', () {
      final int inBereichen = <VocabEntry>[
        for (final CategoryGroup g in kKnowledgeGroups) ...g.entries,
      ].length;
      expect(inBereichen, kKnowledgeEntries.length);
    });

    test('jeder Bereich hat Name, Beschreibung und Themen', () {
      for (final CategoryGroup group in kKnowledgeGroups) {
        expect(group.name.trim(), isNotEmpty);
        expect(group.description.trim(), isNotEmpty);
        expect(group.categories, isNotEmpty, reason: group.name);
      }
    });

    test('Wortschatz und Wissen bleiben getrennte Bereiche', () {
      final Set<String> wissensbereiche = <String>{
        for (final CategoryGroup g in kKnowledgeGroups) g.id,
      };
      for (final CategoryGroup group in kDefaultContent.groups) {
        // Jeder Bereich enthält entweder nur Sprache oder nur Wissen —
        // gemischte Bereiche würden die Übungen wieder unbrauchbar machen.
        final bool wissen = wissensbereiche.contains(group.id);
        for (final VocabEntry entry in group.entries) {
          expect(entry.isLanguage, !wissen, reason: '${group.name}: ${entry.german}');
        }
      }
    });
  });
}
