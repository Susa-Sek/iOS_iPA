import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/content_registry.dart';
import 'package:ipa_testing_github_action/data/curriculum.dart';
import 'package:ipa_testing_github_action/data/knowledge/knowledge_data.dart';
import 'package:ipa_testing_github_action/data/vocabulary_data.dart';
import 'package:ipa_testing_github_action/models/achievement.dart';
import 'package:ipa_testing_github_action/models/subject.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/home_screen.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/widgets/subject_switch.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<LearningState> geladen({DateTime? jetzt}) async {
    final LearningState state =
        LearningState(clock: jetzt == null ? null : () => jetzt);
    await state.load();
    return state;
  }

  group('Fach', () {
    test('Arabisch ist der Anfang', () async {
      final LearningState state = await geladen();
      expect(state.subject, Subject.arabisch);
    });

    test('jeder Bereich gehört zu genau einem Fach', () {
      for (final CategoryGroup group in kGroups) {
        expect(Subject.of(group), Subject.arabisch, reason: group.name);
      }
      for (final CategoryGroup group in kKnowledgeGroups) {
        expect(Subject.of(group), Subject.wissen, reason: group.name);
      }
    });

    test('der Vorrat folgt dem Fach', () async {
      final LearningState state = await geladen();
      expect(state.activeEntries.length, kAllEntries.length);
      expect(state.activeEntries.every((VocabEntry e) => e.isLanguage), isTrue);

      await state.setSubject(Subject.wissen);
      expect(state.activeEntries.length, kKnowledgeEntries.length);
      expect(state.activeEntries.any((VocabEntry e) => e.isLanguage), isFalse);
    });

    test('kein Eintrag des anderen Fachs rutscht in eine Runde', () async {
      final LearningState state = await geladen();
      await state.setSubject(Subject.wissen);
      for (final VocabEntry entry in state.dailySelection()) {
        expect(entry.isLanguage, isFalse, reason: entry.german);
      }
    });

    test('die Bereiche folgen dem Fach', () async {
      final LearningState state = await geladen();
      expect(state.groups.length, kGroups.length);
      await state.setSubject(Subject.wissen);
      expect(state.groups.length, kKnowledgeGroups.length);
    });

    test('die Wahl übersteht einen Neustart', () async {
      final LearningState state = await geladen();
      await state.setSubject(Subject.wissen);

      final LearningState neu = await geladen();
      expect(neu.subject, Subject.wissen);
    });

    test('ein unbekannter gespeicherter Wert fällt auf Arabisch zurück',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LearningState.subjectKey: 'esperanto',
      });
      expect((await geladen()).subject, Subject.arabisch);
    });
  });

  group('Nichts verschwindet beim Umschalten', () {
    test('die Abzeichen hängen nicht am Fach', () async {
      final LearningState state = await geladen();
      // Ein paar Wörter aus beiden Fächern lernen.
      for (final VocabEntry entry in kAllEntries.take(6)) {
        state.markLearned(entry);
      }
      for (final VocabEntry entry in kKnowledgeEntries.take(4)) {
        state.markLearned(entry);
      }

      final AchievementStats vorher = state.achievementStats;
      await state.setSubject(Subject.wissen);
      final AchievementStats nachher = state.achievementStats;

      expect(nachher.learnedWords, vorher.learnedWords);
      expect(nachher.learnedWords, 10);
      expect(state.unlockedAchievements.length,
          (await geladen()).unlockedAchievements.length + 0);
    });

    test('die fälligen Wörter des anderen Fachs bleiben zählbar', () async {
      final DateTime jetzt = DateTime(2026, 5, 1, 9);
      final LearningState state = await geladen(jetzt: jetzt);

      // Je ein Wort aus beiden Fächern falsch beantworten: fällig ab sofort.
      state.demote(kAllEntries.first);
      state.demote(kKnowledgeEntries.first);

      // Angefangen und fällig: genau je eines.
      expect(state.repetitionsDueIn(Subject.arabisch), 1);
      expect(state.repetitionsDueIn(Subject.wissen), 1);

      // `dueCount` zählt auch die nie angesehenen Wörter mit — beide Zahlen
      // haben ihren Zweck, und keine darf beim Umschalten verschwinden.
      expect(state.dueCountIn(Subject.arabisch), kAllEntries.length);
      expect(state.dueCountIn(Subject.wissen), kKnowledgeEntries.length);
      expect(state.dueCountTotal,
          kAllEntries.length + kKnowledgeEntries.length);

      final int summe = state.dueCountTotal;
      await state.setSubject(Subject.wissen);
      expect(state.dueCount, kKnowledgeEntries.length);
      expect(state.dueCountTotal, summe);
    });

    test('gelernte Wörter werden je Fach gezählt', () async {
      final LearningState state = await geladen();
      for (final VocabEntry entry in kAllEntries.take(5)) {
        state.markLearned(entry);
      }
      expect(state.learnedCount, 5);
      expect(state.learnedCountOverall, 5);

      await state.setSubject(Subject.wissen);
      // Im anderen Fach ist noch nichts gelernt — aber nichts verloren.
      expect(state.learnedCount, 0);
      expect(state.learnedCountOverall, 5);
    });

    test('gelernt kann nie mehr sein als vorhanden', () async {
      final LearningState state = await geladen();
      for (final VocabEntry entry in kAllEntries.take(50)) {
        state.markLearned(entry);
      }
      for (final Subject fach in Subject.values) {
        await state.setSubject(fach);
        expect(state.learnedCount, lessThanOrEqualTo(state.totalCount));
        expect(state.overallProgress, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('Ein Inhalt mit nur einem Fach', () {
    const ContentRegistry nurWissen = FixedContent(<CategoryGroup>[]);

    test('leerer Inhalt bricht nicht', () async {
      final LearningState state = LearningState(content: nurWissen);
      await state.load();
      expect(state.activeEntries, isEmpty);
      expect(state.totalCount, 0);
      expect(state.dueCount, 0);
    });

    test('fehlt Arabisch, gilt Wissen', () async {
      final LearningState state = LearningState(
        content: FixedContent(kKnowledgeGroups),
      );
      await state.load();
      expect(state.hasContent(Subject.arabisch), isFalse);
      expect(state.subject, Subject.wissen);
      expect(state.activeEntries, isNotEmpty);
    });
  });

  group('Die Leiste', () {
    testWidgets('ohne angefangene Wörter trägt sie keine Zahl',
        (WidgetTester tester) async {
      // Auf einer frischen Installation ist alles „fällig" — als Marke wäre
      // das eine Zahl, die nie kleiner wird und deshalb nichts sagt.
      final LearningState state = await geladen();
      await tester.pumpWidget(
          wrapScreen(const Scaffold(body: SubjectSwitch()), state: state));
      await tester.pumpAndSettle();

      expect(find.text('${kKnowledgeEntries.length}'), findsNothing);
      expect(state.repetitionsDueIn(Subject.wissen), 0);
    });

    testWidgets('zeigt beide Fächer und wechselt beim Antippen',
        (WidgetTester tester) async {
      final LearningState state = await geladen();
      await tester.pumpWidget(
          wrapScreen(const Scaffold(body: SubjectSwitch()), state: state));
      await tester.pumpAndSettle();

      expect(find.text('Arabisch'), findsOneWidget);
      expect(find.text('Wissen'), findsOneWidget);

      await tester.tap(find.text('Wissen'));
      await tester.pumpAndSettle();
      expect(state.subject, Subject.wissen);
    });

    testWidgets('die Marke steht am nicht gewählten Fach',
        (WidgetTester tester) async {
      final LearningState state = await geladen(jetzt: DateTime(2026, 5, 1, 9));
      state.demote(kKnowledgeEntries.first);

      await tester.pumpWidget(
          wrapScreen(const Scaffold(body: SubjectSwitch()), state: state));
      await tester.pumpAndSettle();

      // Aktiv ist Arabisch, eine Wiederholung steht im Wissen an — die Zahl
      // muss zu sehen sein, sonst versteckt der Fachwechsel Arbeit.
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('mit nur einem Fach verschwindet sie',
        (WidgetTester tester) async {
      final LearningState state =
          LearningState(content: FixedContent(kKnowledgeGroups));
      await state.load();
      await tester.pumpWidget(
          wrapScreen(const Scaffold(body: SubjectSwitch()), state: state));
      await tester.pumpAndSettle();

      expect(find.text('Arabisch'), findsNothing);
      expect(find.text('Wissen'), findsNothing);
    });

    testWidgets('bleibt beim Scrollen der Startseite stehen',
        (WidgetTester tester) async {
      final LearningState state = await geladen();
      await tester.pumpWidget(wrapScreen(const HomeScreen(), state: state));
      await tester.pumpAndSettle();

      expect(find.text('Arabisch'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(find.text('Arabisch'), findsOneWidget);
    });

    for (final double scale in <double>[1.0, 1.5]) {
      testWidgets('Layout auf 320 px bei ${(scale * 100).toInt()} Prozent',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final LearningState state = await geladen(jetzt: DateTime(2026, 5, 1));
        state.demote(kKnowledgeEntries.first);

        await tester.pumpWidget(scale == 1.0
            ? wrapScreen(const HomeScreen(), state: state)
            : wrapScreenScaled(const HomeScreen(), state: state));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
      });
    }
  });
}
