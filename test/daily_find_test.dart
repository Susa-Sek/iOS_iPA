import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/content_registry.dart';
import 'package:ipa_testing_github_action/models/subject.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/home_screen.dart';
import 'package:ipa_testing_github_action/screens/knowledge_home.dart';
import 'package:ipa_testing_github_action/screens/quiz_screen.dart';
import 'package:ipa_testing_github_action/screens/today_screen.dart';
import 'package:ipa_testing_github_action/state/custom_cards.dart';
import 'package:ipa_testing_github_action/state/daily_card_store.dart';
import 'package:ipa_testing_github_action/state/daily_harvest.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';
import 'package:ipa_testing_github_action/state/daily_feed.dart';
import 'package:ipa_testing_github_action/widgets/daily_find_card.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<(LearningState, DailyCardStore)> aufbauen(
    WidgetTester tester,
    Widget screen, {
    List<VocabEntry> funde = const <VocabEntry>[],
    Subject subject = Subject.arabisch,
    Size groesse = const Size(420, 1600),
    double scale = 1,
  }) async {
    tester.view.physicalSize = groesse;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final CustomCardStore gemerkt = CustomCardStore();
    final DailyCardStore tagesfunde = DailyCardStore();
    await tagesfunde.addAll(funde);

    final LearningState state = LearningState(
      store: ProgressStore(),
      content: ContentWithCustomCards(kDefaultContent, gemerkt, tagesfunde),
    );
    await state.load();
    await state.setSubject(subject);

    await tester.pumpWidget(scale == 1
        ? wrapScreen(screen,
            state: state, cards: gemerkt, dailyCards: tagesfunde)
        : wrapScreenScaled(screen,
            scale: scale, state: state, cards: gemerkt, dailyCards: tagesfunde));
    await tester.pumpAndSettle();
    return (state, tagesfunde);
  }

  /// Die Karten, die der echte abgelegte Tagesstoff hergibt.
  Future<List<VocabEntry>> echteErnte() async {
    final DailyFeedService service = await loadedFeed();
    return harvestDaily(service.feed!, currentYear: 2026);
  }

  group('Neu von heute', () {
    testWidgets('steht nur da, wenn es etwas gibt',
        (WidgetTester tester) async {
      await aufbauen(tester, const HomeScreen());
      expect(find.text('Neu von heute'), findsNothing);
      // Die Karte hängt im Baum, nimmt aber keinen Platz ein — deshalb
      // `skipOffstage: false`, sonst übersieht der Finder sie.
      expect(find.byType(DailyFindCard, skipOffstage: false), findsOneWidget);
    });

    testWidgets('zeigt die Karten des Tages mit Namen',
        (WidgetTester tester) async {
      final List<VocabEntry> ernte = await echteErnte();
      await aufbauen(tester, const HomeScreen(), funde: ernte);

      expect(find.text('Neu von heute'), findsOneWidget);
      expect(
        find.text(ernte.length == 1 ? '1 Karte' : '${ernte.length} Karten'),
        findsOneWidget,
      );
    });

    testWidgets('steht auf beiden Startseiten', (WidgetTester tester) async {
      final List<VocabEntry> ernte = await echteErnte();
      await aufbauen(tester, const KnowledgeHome(),
          funde: ernte, subject: Subject.wissen);
      expect(find.text('Neu von heute'), findsOneWidget);
    });

    testWidgets('Antippen öffnet eine Runde mit genau diesen Karten',
        (WidgetTester tester) async {
      final List<VocabEntry> ernte = await echteErnte();
      await aufbauen(tester, const HomeScreen(), funde: ernte);

      await tester.tap(find.text('Neu von heute'));
      await tester.pumpAndSettle();

      expect(find.byType(QuizScreen), findsOneWidget);
      // Die Frage stammt aus der Ernte, nicht aus dem Wortschatz.
      final Set<String> erlaubt = <String>{
        for (final VocabEntry e in ernte) e.prompt,
        for (final VocabEntry e in ernte) e.answer,
      };
      final bool passt = erlaubt.any(
          (String text) => find.text(text).evaluate().isNotEmpty);
      expect(passt, isTrue, reason: 'nichts aus der Ernte auf dem Schirm');
    });

    testWidgets('was gestern kam, steht heute nicht mehr als neu da',
        (WidgetTester tester) async {
      // `latest` ist der jüngste Fund, nicht der ganze Bestand.
      final DailyCardStore store = DailyCardStore();
      await store.addAll(<VocabEntry>[
        const VocabEntry.fact('Gestern', 'Alt'),
      ]);
      expect(store.latest, hasLength(1));
      await store.addAll(<VocabEntry>[
        const VocabEntry.fact('Gestern', 'Alt'),
      ]);
      expect(store.latest, isEmpty, reason: 'nichts wirklich Neues');
    });

    testWidgets('320 px und 150 Prozent Schrift laufen nicht über',
        (WidgetTester tester) async {
      await aufbauen(
        tester,
        const HomeScreen(),
        funde: await echteErnte(),
        groesse: const Size(320, 2000),
        scale: 1.5,
      );
      expect(find.byType(DailyFindCard), findsOneWidget);
    });
  });

  group('Der Schalter im Bereich Heute', () {
    testWidgets('steht da und lässt sich umlegen',
        (WidgetTester tester) async {
      final (_, DailyCardStore funde) =
          await aufbauen(tester, const TodayScreen());

      expect(find.text('Jeden Tag automatisch merken'), findsOneWidget);
      expect(funde.enabled, isTrue);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(funde.enabled, isFalse);
    });

    testWidgets('aus heißt: es kommt nichts mehr dazu',
        (WidgetTester tester) async {
      final (_, DailyCardStore funde) =
          await aufbauen(tester, const TodayScreen());
      await funde.setEnabled(false);
      await funde.addAll(await echteErnte());
      expect(funde.isEmpty, isTrue);
    });

    testWidgets('alle löschen nimmt den Lernstand mit',
        (WidgetTester tester) async {
      final List<VocabEntry> ernte = await echteErnte();
      final (LearningState state, DailyCardStore funde) =
          await aufbauen(tester, const TodayScreen(), funde: ernte);

      state.promote(ernte.first);
      expect(state.progressOfWord(ernte.first).box, 1);

      await tester.tap(find.text('Alle löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      expect(funde.isEmpty, isTrue);
      // Sonst wüchse der Lernstand mit Einträgen zu Karten, die weg sind.
      expect(state.progressOfWord(ernte.first).box, 0);
    });

    testWidgets('abbrechen löscht nichts', (WidgetTester tester) async {
      final (_, DailyCardStore funde) = await aufbauen(
          tester, const TodayScreen(), funde: await echteErnte());
      final int vorher = funde.length;

      await tester.tap(find.text('Alle löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(funde.length, vorher);
    });
  });
}
