import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/typing_check.dart';

const VocabEntry _leber = VocabEntry.question(
  'Welches Organ bildet die Galle?',
  'Die Leber',
  distractors: <String>['Die Niere', 'Die Milz', 'Der Magen'],
  explanation: 'Die Nieren filtern das Blut.',
);

const VocabEntry _aequator = VocabEntry.fact(
  'Äquator',
  'Linie des größten Erdumfangs',
  explanation: 'Rund 40.075 Kilometer lang.',
);

const VocabEntry _mauerfall = VocabEntry.question(
  'In welchem Jahr fiel die Berliner Mauer?',
  '1989',
  distractors: <String>['1987', '1990', '1991'],
  explanation: 'Am 9. November 1989.',
);

const VocabEntry _haus = VocabEntry('Haus', 'بَيْت', 'bait');

void main() {
  group('Was getippt wird', () {
    test('bei einer Vokabel die deutsche Seite', () {
      // Ein arabisches Wort lässt sich auf einer deutschen Tastatur nicht
      // eingeben — die Übung wäre sonst unlösbar statt schwer.
      expect(typedTarget(_haus), 'Haus');
      expect(typedPrompt(_haus), 'بَيْت');
    });

    test('bei einer Wissenskarte die Antwort', () {
      expect(typedTarget(_leber), 'Die Leber');
      expect(typedPrompt(_leber), 'Welches Organ bildet die Galle?');
      expect(typedTarget(_aequator), 'Linie des größten Erdumfangs');
    });
  });

  group('Richtig getippt', () {
    test('wortgleich', () {
      expect(checkTyped('Die Leber', _leber).verdict, TypingVerdict.exact);
      expect(checkTyped('1989', _mauerfall).verdict, TypingVerdict.exact);
      expect(checkTyped('Haus', _haus).verdict, TypingVerdict.exact);
    });

    test('Groß- und Kleinschreibung entscheidet nichts', () {
      expect(checkTyped('die leber', _leber).verdict, TypingVerdict.exact);
      expect(checkTyped('HAUS', _haus).verdict, TypingVerdict.exact);
    });

    test('der Artikel darf fehlen', () {
      expect(checkTyped('Leber', _leber).verdict, TypingVerdict.exact);
    });

    test('Umlautpunkte dürfen fehlen', () {
      expect(
          checkTyped('Linie des grossten Erdumfangs', _aequator).verdict,
          TypingVerdict.exact);
    });

    test('Satzzeichen und Leerraum fallen weg', () {
      expect(checkTyped('  die Leber.  ', _leber).verdict, TypingVerdict.exact);
    });
  });

  group('Fast richtig', () {
    test('ein Buchstabe daneben zählt als gewusst', () {
      final TypingResult r = checkTyped('Die Lebar', _leber);
      expect(r.verdict, TypingVerdict.almost);
      expect(r.isCorrect, isTrue);
      // Die richtige Schreibweise wird trotzdem gezeigt.
      expect(r.answer, 'Die Leber');
    });

    test('ein fehlender Buchstabe in einem langen Wort auch', () {
      expect(checkTyped('Linie des grössten Erdumfang', _aequator).verdict,
          TypingVerdict.almost);
    });

    test('bei kurzen Antworten zählt jede Abweichung', () {
      // „1988" ist nicht fast „1989", sondern ein anderes Jahr.
      expect(checkTyped('1988', _mauerfall).verdict, TypingVerdict.wrong);
      expect(checkTyped('Maus', _haus).verdict, TypingVerdict.wrong);
    });
  });

  group('Falsch getippt', () {
    test('etwas ganz anderes', () {
      expect(checkTyped('Die Niere', _leber).verdict, TypingVerdict.wrong);
      expect(checkTyped('1961', _mauerfall).verdict, TypingVerdict.wrong);
    });

    test('leere Eingabe ist nie richtig', () {
      expect(checkTyped('', _leber).verdict, TypingVerdict.wrong);
      expect(checkTyped('   ', _leber).verdict, TypingVerdict.wrong);
      expect(checkTyped('...', _leber).verdict, TypingVerdict.wrong);
    });

    test('ein Ablenker ist nie richtig', () {
      for (final VocabEntry entry in kKnowledgeEntries) {
        for (final String ablenker in entry.distractors) {
          expect(checkTyped(ablenker, entry).isCorrect, isFalse,
              reason: '„$ablenker" bei „${entry.german}"');
        }
      }
    });
  });

  group('Welche Einträge sich eignen', () {
    test('lange Antworten fallen heraus', () {
      const VocabEntry lang = VocabEntry.fact('Binnenmarkt',
          'Freier Verkehr von Waren, Personen, Diensten und Kapital');
      expect(isTypeable(lang), isFalse);
    });

    test('kurze Vokabeln und kurze Antworten eignen sich', () {
      expect(isTypeable(_haus), isTrue);
      expect(isTypeable(_leber), isTrue);
      expect(isTypeable(_mauerfall), isTrue);
    });

    test('es gibt genug davon für eine Runde', () {
      final int wortschatz = kAllEntries.where(isTypeable).length;
      final int wissen = kKnowledgeEntries.where(isTypeable).length;
      expect(wortschatz, greaterThan(100));
      expect(wissen, greaterThan(30));
    });

    test('jeder geeignete Eintrag ist mit seiner eigenen Antwort lösbar', () {
      // Die Probe aufs Exempel: Wer die Antwort abschreibt, muss bestehen.
      for (final VocabEntry entry
          in <VocabEntry>[...kAllEntries, ...kKnowledgeEntries]
              .where(isTypeable)) {
        expect(checkTyped(typedTarget(entry), entry).verdict,
            TypingVerdict.exact,
            reason: entry.german);
      }
    });
  });
}
