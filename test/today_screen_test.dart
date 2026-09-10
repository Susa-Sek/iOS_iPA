import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/content_registry.dart';
import 'package:ipa_testing_github_action/models/vocabulary.dart';
import 'package:ipa_testing_github_action/screens/home_screen.dart';
import 'package:ipa_testing_github_action/screens/today_screen.dart';
import 'package:ipa_testing_github_action/state/custom_cards.dart';
import 'package:ipa_testing_github_action/state/daily_feed.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';

import 'helpers.dart';

/// Telefongrößen, gegen die der Bereich geprüft wird. Ein Überlauf lässt den
/// Test fehlschlagen — genau darum ist bloßes Aufbauen schon eine Prüfung.
const List<Size> _sizes = <Size>[
  Size(320, 568),
  Size(390, 844),
  Size(430, 932),
];

Future<void> _withSize(
  WidgetTester tester,
  Size size,
  Future<void> Function() body,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await body();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// Eine hohe Prüffläche, damit die Liste alle Abschnitte wirklich baut —
  /// ein `ListView` erzeugt nur, was sichtbar wäre.
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 4400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('Bereich „Heute"', () {
    testWidgets('zeigt alle drei Abschnitte', (WidgetTester tester) async {
      tall(tester);
      final DailyFeedService feed = await loadedFeed();
      await tester.pumpWidget(wrapScreen(const TodayScreen(), feed: feed));
      await tester.pumpAndSettle();

      expect(find.text('Artikel des Tages'), findsOneWidget);
      expect(find.text('Was geschah heute'), findsOneWidget);
      expect(find.text('Nachrichten'), findsOneWidget);
      expect(find.text('Kragenhai'), findsOneWidget);
      expect(find.textContaining('CC BY-SA'), findsOneWidget);
    });

    testWidgets('ohne Inhalt ein Hinweis statt einer leeren Seite',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapScreen(const TodayScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('braucht Netz'), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
    });

    testWidgets('ein alter Stand nennt sein Datum',
        (WidgetTester tester) async {
      final DailyFeedService feed = await loadedFeed();
      // Der Dienst hat den Stand von gestern und heute kein Netz.
      final DailyFeedService gestern = DailyFeedService(
        backend: OfflineFeedBackend(),
        clock: () => DateTime(2026, 9, 11, 8),
      );
      await gestern.load();
      await gestern.ensureFresh();

      expect(feed.feed, isNotNull);
      expect(gestern.status, FeedStatus.offline);
      expect(gestern.feed!.day, DateTime(2026, 9, 10));

      await tester.pumpWidget(wrapScreen(const TodayScreen(), feed: gestern));
      await tester.pumpAndSettle();
      expect(find.textContaining('letzter Stand vom 10.9.2026'), findsOneWidget);
    });

    testWidgets('merkt einen Artikel als Karte', (WidgetTester tester) async {
      tall(tester);
      final DailyFeedService feed = await loadedFeed();
      final CustomCardStore cards = CustomCardStore();
      await cards.load();

      await tester.pumpWidget(
          wrapScreen(const TodayScreen(), feed: feed, cards: cards));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Als Karte merken').first);
      await tester.pumpAndSettle();

      expect(cards.cards, hasLength(1));
      expect(cards.cards.single.german, 'Kragenhai');
      expect(find.text('Gemerkt'), findsWidgets);
      expect(find.textContaining('Meine Karten'), findsOneWidget);
    });

    testWidgets('eine Meldung lässt sich nicht merken',
        (WidgetTester tester) async {
      tall(tester);
      final DailyFeedService feed = await loadedFeed();
      await tester.pumpWidget(wrapScreen(const TodayScreen(), feed: feed));
      await tester.pumpAndSettle();

      // Ein Artikel und drei Ereignisse — vier Knöpfe, kein fünfter für die
      // vier Meldungen.
      expect(find.text('Als Karte merken'), findsNWidgets(4));
      expect(find.text('tagesschau.de öffnen'), findsNWidgets(4));
    });

    testWidgets('die gemerkte Karte landet im Lernvorrat',
        (WidgetTester tester) async {
      tall(tester);
      final DailyFeedService feed = await loadedFeed();
      final CustomCardStore cards = CustomCardStore();
      final LearningState state = LearningState(
        content: ContentWithCustomCards(kDefaultContent, cards),
      );
      await state.load();
      cards.addListener(state.contentChanged);
      final int vorher = state.totalCount;

      await tester.pumpWidget(wrapScreen(const TodayScreen(),
          feed: feed, cards: cards, state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Als Karte merken').first);
      await tester.pumpAndSettle();

      expect(state.totalCount, vorher + 1);
      expect(
        state.content.categoryById(ContentWithCustomCards.customCategoryId),
        isNotNull,
      );
    });
  });

  group('Lernweg', () {
    testWidgets('zeigt die gemerkten Karten als eigenes Thema',
        (WidgetTester tester) async {
      tall(tester);
      final CustomCardStore cards = CustomCardStore();
      await cards.add(const VocabEntry.fact('Kragenhai', 'Ein Tiefseehai'));
      final LearningState state = LearningState(
        content: ContentWithCustomCards(kDefaultContent, cards),
      );
      await state.load();

      await tester.pumpWidget(
          wrapScreen(const HomeScreen(), cards: cards, state: state));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.text('Gemerkt'), findsOneWidget);
    });

    testWidgets('ohne gemerkte Karten gibt es das Thema nicht',
        (WidgetTester tester) async {
      tall(tester);
      final CustomCardStore cards = CustomCardStore();
      await cards.load();
      final LearningState state = LearningState(
        content: ContentWithCustomCards(kDefaultContent, cards),
      );
      await state.load();

      await tester.pumpWidget(
          wrapScreen(const HomeScreen(), cards: cards, state: state));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.text('Gemerkt'), findsNothing);
    });
  });

  group('Layout', () {
    for (final Size size in _sizes) {
      testWidgets('${size.width.toInt()}px', (WidgetTester tester) async {
        await _withSize(tester, size, () async {
          final DailyFeedService feed = await loadedFeed();
          await tester.pumpWidget(wrapScreen(const TodayScreen(), feed: feed));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(ListView), const Offset(0, -900));
          await tester.pumpAndSettle();
        });
      });
    }

    testWidgets('bei 150 % Schrift', (WidgetTester tester) async {
      await _withSize(tester, const Size(320, 568), () async {
        final DailyFeedService feed = await loadedFeed();
        await tester
            .pumpWidget(wrapScreenScaled(const TodayScreen(), feed: feed));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -900));
        await tester.pumpAndSettle();
      });
    });
  });
}
