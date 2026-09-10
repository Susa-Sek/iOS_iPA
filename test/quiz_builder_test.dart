import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/arabic.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/state/quiz_builder.dart';

/// Eine Wissensfrage bringt ihre Falschantworten mit.
const VocabEntry _frage = VocabEntry.question(
  'Welcher Fluss ist der längste Europas?',
  'Wolga',
  distractors: <String>['Donau', 'Rhein', 'Dnepr'],
  explanation: 'Die Wolga ist rund 3.530 Kilometer lang.',
);

const VocabEntry _karte = VocabEntry.fact(
  'Inflation',
  'Anhaltender Anstieg des Preisniveaus',
  explanation: 'Für dasselbe Geld bekommt man weniger.',
);

/// Ein gemischter Vorrat, wie er entsteht, sobald Wortschatz und Wissen
/// nebeneinanderliegen.
const List<VocabEntry> _gemischt = <VocabEntry>[
  VocabEntry('Haus', 'بَيْت', 'bait'),
  VocabEntry('Buch', 'كِتَاب', 'kitāb'),
  VocabEntry('Tür', 'بَاب', 'bāb'),
  VocabEntry('Wasser', 'مَاء', 'māʾ'),
  VocabEntry.fact('Wolga', 'Längster Fluss Europas'),
  VocabEntry.fact('Everest', 'Höchster Berg der Erde'),
  VocabEntry.fact('Algorithmus', 'Eindeutige Folge von Anweisungen'),
  VocabEntry.fact('Photosynthese', 'Zucker aus Licht'),
];

void main() {
  final Random random = Random(42);
  final List<VocabEntry> vokabeln = kCategories.first.entries;

  group('Vokabelfragen', () {
    test('eine Runde hat so viele Fragen wie gewünscht', () {
      final List<QuizQuestion> round = buildQuizRound(
        ordered: vokabeln,
        pool: vokabeln,
        direction: QuizDirection.arabicToGerman,
        random: random,
      );
      expect(round.length, min(kQuestionsPerRound, vokabeln.length));
    });

    test('vier Antworten, die richtige dabei, keine doppelt', () {
      final List<QuizQuestion> round = buildQuizRound(
        ordered: vokabeln,
        pool: vokabeln,
        direction: QuizDirection.arabicToGerman,
        random: random,
      );
      for (final QuizQuestion q in round) {
        expect(q.options.length, 4, reason: q.prompt);
        expect(q.options, contains(q.answer));
        expect(q.options.toSet().length, 4, reason: q.prompt);
        expect(q.isCorrect(q.answer), isTrue);
      }
    });

    test('Arabisch → Deutsch fragt arabisch und antwortet deutsch', () {
      final QuizQuestion q = buildQuizRound(
        ordered: <VocabEntry>[vokabeln.first],
        pool: vokabeln,
        direction: QuizDirection.arabicToGerman,
        random: random,
      ).single;
      expect(q.prompt, vokabeln.first.arabic);
      expect(q.answer, vokabeln.first.german);
      expect(q.promptIsArabic, isTrue);
      expect(q.answersAreArabic, isFalse);
    });

    test('Deutsch → Arabisch dreht beides um', () {
      final QuizQuestion q = buildQuizRound(
        ordered: <VocabEntry>[vokabeln.first],
        pool: vokabeln,
        direction: QuizDirection.germanToArabic,
        random: random,
      ).single;
      expect(q.prompt, vokabeln.first.german);
      expect(q.answer, vokabeln.first.arabic);
      expect(q.promptIsArabic, isFalse);
      expect(q.answersAreArabic, isTrue);
    });

    test('Hören fragt nach der deutschen Bedeutung', () {
      final QuizQuestion q = buildQuizRound(
        ordered: <VocabEntry>[vokabeln.first],
        pool: vokabeln,
        direction: QuizDirection.listening,
        random: random,
      ).single;
      expect(q.answer, vokabeln.first.german);
    });
  });

  group('Wissensfragen', () {
    test('die mitgelieferten Falschantworten werden benutzt', () {
      final QuizQuestion q = buildQuizRound(
        ordered: <VocabEntry>[_frage],
        pool: vokabeln,
        direction: QuizDirection.arabicToGerman,
        random: random,
      ).single;

      expect(q.prompt, 'Welcher Fluss ist der längste Europas?');
      expect(q.answer, 'Wolga');
      expect(q.options, containsAll(<String>['Wolga', 'Donau', 'Rhein', 'Dnepr']));
      expect(q.options.length, 4);
      // Keine arabischen Wörter als Ablenker.
      expect(q.answersAreArabic, isFalse);
      expect(q.promptIsArabic, isFalse);
    });

    test('die Richtung wird bei Wissensfragen ignoriert', () {
      for (final QuizDirection direction in QuizDirection.values) {
        final QuizQuestion q = buildQuizRound(
          ordered: <VocabEntry>[_frage],
          pool: vokabeln,
          direction: direction,
          random: random,
        ).single;
        expect(q.answer, 'Wolga', reason: direction.name);
        expect(q.prompt, contains('Fluss'), reason: direction.name);
      }
    });

    test('die Erklärung wird durchgereicht', () {
      final QuizQuestion q = buildQuizRound(
        ordered: <VocabEntry>[_frage],
        pool: vokabeln,
        direction: QuizDirection.arabicToGerman,
        random: random,
      ).single;
      expect(q.explanation, contains('3.530'));
    });

    test('eine Begriffskarte ohne Ablenker wird aufgefüllt', () {
      final QuizQuestion q = buildQuizRound(
        ordered: <VocabEntry>[_karte],
        pool: vokabeln,
        direction: QuizDirection.arabicToGerman,
        random: random,
      ).single;
      expect(q.prompt, 'Inflation');
      expect(q.answer, 'Anhaltender Anstieg des Preisniveaus');
      expect(q.options.length, 4);
      expect(q.options, contains(q.answer));
    });
  });

  group('Randfälle', () {
    test('ein winziger Vorrat bricht nicht', () {
      final List<VocabEntry> klein = vokabeln.take(2).toList();
      final List<QuizQuestion> round = buildQuizRound(
        ordered: klein,
        pool: klein,
        direction: QuizDirection.arabicToGerman,
        random: random,
      );
      expect(round.length, 2);
      for (final QuizQuestion q in round) {
        expect(q.options, contains(q.answer));
        expect(q.options.length, lessThanOrEqualTo(4));
        expect(q.options.toSet().length, q.options.length);
      }
    });

    test('ein leerer Vorrat liefert keine Fragen', () {
      expect(
        buildQuizRound(
          ordered: const <VocabEntry>[],
          pool: const <VocabEntry>[],
          direction: QuizDirection.arabicToGerman,
          random: random,
        ),
        isEmpty,
      );
    });
  });

  group('Gemischter Vorrat', () {
    test('eine Vokabel bekommt keine deutschen Ablenker', () {
      // Sonst wäre die richtige Antwort die einzige arabische — man müsste
      // die Vokabel nicht kennen, um sie zu treffen.
      final List<QuizQuestion> runde = buildQuizRound(
        ordered: <VocabEntry>[_gemischt.first],
        pool: _gemischt,
        direction: QuizDirection.germanToArabic,
        random: Random(3),
      );
      expect(runde.single.options, hasLength(4));
      for (final String option in runde.single.options) {
        expect(hasTashkil(option) || withoutTashkil(option) != option, isTrue,
            reason: '„$option" ist keine arabische Antwort');
      }
    });

    test('eine Wissensfrage bekommt keine arabischen Ablenker', () {
      final VocabEntry wissen =
          _gemischt.firstWhere((VocabEntry e) => !e.isLanguage);
      final List<QuizQuestion> runde = buildQuizRound(
        ordered: <VocabEntry>[wissen],
        pool: _gemischt,
        direction: QuizDirection.arabicToGerman,
        random: Random(5),
      );
      expect(runde.single.options, hasLength(4));
      for (final String option in runde.single.options) {
        expect(RegExp(r'[\u0600-\u06FF]').hasMatch(option), isFalse,
            reason: '„$option" ist arabisch');
      }
    });

    test('reicht die eigene Art nicht, wird trotzdem aufgefüllt', () {
      // Zwei Wissenseinträge ergeben nur zwei Antworten — die fehlenden
      // dürfen dann auch aus dem übrigen Vorrat kommen.
      const List<VocabEntry> knapp = <VocabEntry>[
        VocabEntry.fact('Wolga', 'Längster Fluss Europas'),
        VocabEntry.fact('Everest', 'Höchster Berg der Erde'),
        VocabEntry('Haus', 'بَيْت', 'bait'),
        VocabEntry('Buch', 'كِتَاب', 'kitāb'),
      ];
      final List<QuizQuestion> runde = buildQuizRound(
        ordered: <VocabEntry>[knapp.first],
        pool: knapp,
        direction: QuizDirection.arabicToGerman,
        random: Random(7),
      );
      expect(runde.single.options, hasLength(4));
      expect(runde.single.options.toSet(), hasLength(4));
      expect(runde.single.options, contains('Längster Fluss Europas'));
    });
  });
}
