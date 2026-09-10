import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
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
}
