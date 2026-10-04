import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipa_testing_github_action/data/azkar_data.dart';
import 'package:ipa_testing_github_action/models/azkar.dart';
import 'package:ipa_testing_github_action/state/azkar_store.dart';
import 'package:ipa_testing_github_action/state/learning_state.dart';
import 'package:ipa_testing_github_action/state/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  List<Dhikr> pensum([AzkarTime t = AzkarTime.morgens]) =>
      azkarFor(time: t, level: AzkarLevel.leicht);

  Future<AzkarStore> storeAt(DateTime jetzt) async {
    final AzkarStore store = AzkarStore(clock: () => jetzt);
    await store.load();
    return store;
  }

  /// Das ganze Pensum einer Hälfte durchsprechen.
  Future<void> allesSprechen(
      AzkarStore store, AzkarTime t, List<Dhikr> p) async {
    for (final Dhikr d in p) {
      for (int i = 0; i < d.count; i++) {
        await store.tippe(t, d, p);
      }
    }
  }

  group('Der Zähler', () {
    test('zählt hoch bis zur Anzahl und nicht darüber', () async {
      final AzkarStore store = await storeAt(DateTime(2026, 10, 4, 7));
      final List<Dhikr> p = pensum();
      final Dhikr dreimal = p.firstWhere((Dhikr d) => d.count == 3);

      expect(store.zaehler(AzkarTime.morgens, dreimal), 0);
      await store.tippe(AzkarTime.morgens, dreimal, p);
      expect(store.zaehler(AzkarTime.morgens, dreimal), 1);
      expect(store.istFertig(AzkarTime.morgens, dreimal), isFalse);

      await store.tippe(AzkarTime.morgens, dreimal, p);
      await store.tippe(AzkarTime.morgens, dreimal, p);
      expect(store.istFertig(AzkarTime.morgens, dreimal), isTrue);

      await store.tippe(AzkarTime.morgens, dreimal, p);
      expect(store.zaehler(AzkarTime.morgens, dreimal), 3,
          reason: 'nicht über das Ziel hinaus');
    });

    test('lässt sich zurücksetzen', () async {
      final AzkarStore store = await storeAt(DateTime(2026, 10, 4, 7));
      final List<Dhikr> p = pensum();
      await store.tippe(AzkarTime.morgens, p.first, p);
      await store.zuruecksetzen(AzkarTime.morgens, p.first);
      expect(store.zaehler(AzkarTime.morgens, p.first), 0);
    });

    test('Morgen und Abend zählen getrennt', () async {
      final AzkarStore store = await storeAt(DateTime(2026, 10, 4, 7));
      final List<Dhikr> p = pensum();
      await store.tippe(AzkarTime.morgens, p.first, p);
      expect(store.zaehler(AzkarTime.morgens, p.first), 1);
      expect(store.zaehler(AzkarTime.abends, p.first), 0);
    });

    test('überlebt den Neustart', () async {
      final List<Dhikr> p = pensum();
      final AzkarStore erst = await storeAt(DateTime(2026, 10, 4, 7));
      await erst.tippe(AzkarTime.morgens, p.first, p);

      final AzkarStore wieder = await storeAt(DateTime(2026, 10, 4, 9));
      expect(wieder.zaehler(AzkarTime.morgens, p.first), 1);
    });
  });

  group('Der Tag rollt um', () {
    test('am nächsten Tag stehen die Zähler wieder auf null', () async {
      final List<Dhikr> p = pensum();
      final AzkarStore erst = await storeAt(DateTime(2026, 10, 4, 7));
      await allesSprechen(erst, AzkarTime.morgens, p);
      expect(erst.istHaelfteFertig(AzkarTime.morgens, p), isTrue);

      final AzkarStore morgen = await storeAt(DateTime(2026, 10, 5, 7));
      expect(morgen.istHaelfteFertig(AzkarTime.morgens, p), isFalse);
      expect(morgen.zaehler(AzkarTime.morgens, p.first), 0);
    });
  });

  group('Die eigene Serie', () {
    test('zählt Tag für Tag weiter', () async {
      final List<Dhikr> p = pensum();
      for (int tag = 4; tag <= 7; tag++) {
        final AzkarStore store = await storeAt(DateTime(2026, 10, tag, 7));
        await allesSprechen(store, AzkarTime.morgens, p);
        expect(store.serie(AzkarTime.morgens), tag - 3, reason: 'Tag $tag');
      }
    });

    test('ein ausgelassener Tag fängt sie neu an', () async {
      final List<Dhikr> p = pensum();
      final AzkarStore a = await storeAt(DateTime(2026, 10, 4, 7));
      await allesSprechen(a, AzkarTime.morgens, p);
      final AzkarStore b = await storeAt(DateTime(2026, 10, 5, 7));
      await allesSprechen(b, AzkarTime.morgens, p);
      expect(b.serie(AzkarTime.morgens), 2);

      // Der 6. fällt aus.
      final AzkarStore c = await storeAt(DateTime(2026, 10, 7, 7));
      await allesSprechen(c, AzkarTime.morgens, p);
      expect(c.serie(AzkarTime.morgens), 1);
    });

    test('sie reißt nicht am Tag darauf, bevor man gesprochen hat', () async {
      // Sonst stünde den halben Tag über eine Null da, obwohl nichts
      // verloren ist.
      final List<Dhikr> p = pensum();
      final AzkarStore a = await storeAt(DateTime(2026, 10, 4, 7));
      await allesSprechen(a, AzkarTime.morgens, p);

      final AzkarStore b = await storeAt(DateTime(2026, 10, 5, 7));
      expect(b.serie(AzkarTime.morgens), 1);
      expect(b.heuteSchonFertig(AzkarTime.morgens), isFalse);

      // Zwei Tage später ist sie weg.
      final AzkarStore c = await storeAt(DateTime(2026, 10, 6, 7));
      expect(c.serie(AzkarTime.morgens), 0);
    });

    test('Morgen und Abend haben eigene Serien', () async {
      final List<Dhikr> morgens = pensum();
      final List<Dhikr> abends = pensum(AzkarTime.abends);
      final AzkarStore a = await storeAt(DateTime(2026, 10, 4, 7));
      await allesSprechen(a, AzkarTime.morgens, morgens);
      await allesSprechen(a, AzkarTime.abends, abends);
      final AzkarStore b = await storeAt(DateTime(2026, 10, 5, 7));
      await allesSprechen(b, AzkarTime.morgens, morgens);

      expect(b.serie(AzkarTime.morgens), 2);
      expect(b.serie(AzkarTime.abends), 1,
          reason: 'der Abend hängt nicht am Morgen');
    });

    test('ein halbes Pensum zählt nicht', () async {
      final AzkarStore store = await storeAt(DateTime(2026, 10, 4, 7));
      final List<Dhikr> p = pensum();
      await store.tippe(AzkarTime.morgens, p.first, p);
      expect(store.serie(AzkarTime.morgens), 0);
      expect(store.heuteSchonFertig(AzkarTime.morgens), isFalse);
    });

    test('eine höhere Stufe macht das Pensum größer', () async {
      // Wer auf „Vollständig" steht, ist mit den fünf leichten noch nicht
      // durch — sonst wäre die Stufe ein Trick zum Abkürzen.
      final AzkarStore store = await storeAt(DateTime(2026, 10, 4, 7));
      final List<Dhikr> leicht = pensum();
      final List<Dhikr> alles =
          azkarFor(time: AzkarTime.morgens, level: AzkarLevel.vollstaendig);
      await allesSprechen(store, AzkarTime.morgens, leicht);

      expect(store.istHaelfteFertig(AzkarTime.morgens, leicht), isTrue);
      expect(store.istHaelfteFertig(AzkarTime.morgens, alles), isFalse);
    });
  });

  group('Die beiden Spuren berühren sich nicht', () {
    test('Azkar geben kein XP, keine Lernserie, keinen Jokertag', () async {
      // Der Test, der die Trennung festhält: Gottesdienst gegen Punkte zu
      // tauschen wäre schief.
      final LearningState lernen = LearningState(store: ProgressStore());
      await lernen.load();
      final int xpVorher = lernen.xp;
      final int serieVorher = lernen.dayStreak;
      final int antwortenVorher = lernen.answered;
      final int jokerVorher = lernen.freezes;

      final AzkarStore store = await storeAt(DateTime(2026, 10, 4, 7));
      await allesSprechen(store, AzkarTime.morgens, pensum());
      await allesSprechen(store, AzkarTime.abends, pensum(AzkarTime.abends));

      expect(lernen.xp, xpVorher);
      expect(lernen.dayStreak, serieVorher);
      expect(lernen.answered, antwortenVorher);
      expect(lernen.freezes, jokerVorher);
    });

    test('der Lernstand liegt in einem anderen Schlüssel', () async {
      final AzkarStore store = await storeAt(DateTime(2026, 10, 4, 7));
      await allesSprechen(store, AzkarTime.morgens, pensum());

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AzkarStore.storageKey), isNotNull);
      expect(prefs.getString(ProgressStore.storageKey), isNull,
          reason: 'die Azkar fassen den Lernstand nicht an');
    });
  });

  group('Zurücksetzen', () {
    test('räumt Zähler und Serien ab', () async {
      final AzkarStore store = await storeAt(DateTime(2026, 10, 4, 7));
      await allesSprechen(store, AzkarTime.morgens, pensum());
      await store.reset();
      expect(store.serie(AzkarTime.morgens), 0);
      expect(store.zaehler(AzkarTime.morgens, pensum().first), 0);
    });
  });
}
