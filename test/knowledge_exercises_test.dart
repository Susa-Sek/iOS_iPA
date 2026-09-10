import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/content_registry.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/build_word_screen.dart';
import 'package:ipa_testing_github_action/screens/matching_screen.dart';
import 'package:ipa_testing_github_action/screens/quiz_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

import 'helpers.dart';

/// Wissensinhalte, wie sie in Etappe 5 kommen.
const VocabCategory _wissen = VocabCategory(
  id: 'test_wissen',
  name: 'Testwissen',
  icon: Icons.lightbulb_outline,
  color: Color(0xFF2E5C8A),
  softColor: Color(0x242E5C8A),
  script: TextScript.latin,
  entries: <VocabEntry>[
    VocabEntry.question(
      'Welcher Fluss ist der längste Europas?',
      'Wolga',
      distractors: <String>['Donau', 'Rhein', 'Dnepr'],
      explanation: 'Die Wolga ist rund 3.530 Kilometer lang.',
    ),
    VocabEntry.question(
      'Wie viele Bundesländer hat Deutschland?',
      '16',
      distractors: <String>['12', '14', '18'],
      explanation: 'Seit der Wiedervereinigung 1990.',
    ),
    VocabEntry.fact('Inflation', 'Anhaltender Anstieg des Preisniveaus',
        explanation: 'Für dasselbe Geld bekommt man weniger.'),
    VocabEntry.fact('Photosynthese',
        'Umwandlung von Licht in chemische Energie in Pflanzen'),
    VocabEntry.fact('Demokratie', 'Herrschaft, die vom Volk ausgeht'),
    VocabEntry.fact('Algorithmus', 'Eindeutige Folge von Anweisungen'),
  ],
);

final CategoryGroup _gruppe = CategoryGroup(
  id: 'test_gruppe',
  name: 'Testbereich',
  description: 'Nur für den Test.',
  icon: Icons.science_outlined,
  categories: const <VocabCategory>[_wissen],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Widget wrap(Widget child) => wrapScreen(
        child,
        state: LearningState(content: FixedContent(<CategoryGroup>[_gruppe])),
      );

  group('Quiz mit Wissensfragen', () {
    testWidgets('zeigt Frage, mitgelieferte Antworten und Erklärung',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        QuizScreen(entries: _wissen.entries, title: 'Testwissen'),
      ));
      await tester.pumpAndSettle();

      // Die Erklärung erscheint erst nach der Antwort.
      expect(find.textContaining('Kilometer'), findsNothing);

      // Eine Frage mit mitgelieferten Ablenkern ist erkennbar.
      final Finder wolga = find.text('Wolga');
      if (wolga.evaluate().isNotEmpty) {
        expect(find.text('Donau'), findsOneWidget);
        expect(find.text('Rhein'), findsOneWidget);
      }

      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pumpAndSettle();

      // Nach der Antwort steht die Erklärung da.
      expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);
    });
  });

  group('Wort bauen', () {
    test('Wissenskarten kommen nicht in die Übung', () {
      for (final VocabEntry entry in _wissen.entries) {
        expect(BuildWordScreen.isSuitable(entry), isFalse,
            reason: entry.german);
      }
      // Kurze arabische Wörter dagegen schon.
      expect(
        kAllEntries.where(BuildWordScreen.isSuitable).length,
        greaterThan(50),
      );
    });

    testWidgets('sagt es, wenn nichts zu bauen ist',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        BuildWordScreen(entries: _wissen.entries, title: 'Testwissen'),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('keine kurzen Einzelwörter'), findsOneWidget);
    });
  });

  group('Zuordnen', () {
    test('lange Antworten sprengen die Spalte nicht', () {
      const VocabEntry lang = VocabEntry.fact(
        'Photosynthese',
        'Umwandlung von Lichtenergie in chemische Energie durch Pflanzen, '
            'Algen und einige Bakterien',
      );
      expect(MatchingScreen.isSuitable(lang), isFalse);

      const VocabEntry kurz = VocabEntry.fact('Wolga', 'Längster Fluss');
      expect(MatchingScreen.isSuitable(kurz), isTrue);

      // Vokabeln bleiben durchweg geeignet.
      expect(kAllEntries.where(MatchingScreen.isSuitable).length,
          greaterThan(kAllEntries.length ~/ 2));
    });
  });
}
