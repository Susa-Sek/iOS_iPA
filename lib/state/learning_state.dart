import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievements_data.dart';
import '../data/content_registry.dart';
import '../models/achievement.dart';
import '../models/subject.dart';
import '../models/vocabulary.dart';
import 'progress_store.dart';
import 'daily_quests.dart';
import 'session_plan.dart';
import 'word_progress.dart';

/// Tracks what the learner knows, when each word is due again, and how the
/// last days went. Everything is written to the device through
/// [ProgressStore], so closing the app no longer loses the progress.
class LearningState extends ChangeNotifier {
  LearningState({
    ProgressStore? store,
    DateTime Function()? clock,
    ContentRegistry? content,
  })  : _store = store ?? ProgressStore(),
        _now = clock ?? DateTime.now,
        _content = content ?? kDefaultContent;

  final ProgressStore _store;
  final DateTime Function() _now;

  /// Woher die Inhalte kommen. Der Lernkern kennt keine einzelne Sprache
  /// mehr, nur noch diese Registry.
  final ContentRegistry _content;

  ContentRegistry get content => _content;

  // ---- Fach ---------------------------------------------------------------

  /// Der Schlüssel des gewählten Fachs. Das Präfix bleibt „arabisch_lernen",
  /// auch wenn die App anders heißt — siehe `naming_test.dart`.
  static const String subjectKey = 'arabisch_lernen.subject';

  Subject _subject = Subject.arabisch;

  /// Das Fach, in dem gerade gelernt wird. Es ist immer genau eines aktiv.
  ///
  /// Hat das gewählte Fach keine Inhalte — bei einem Inhalt, der nur eines
  /// von beiden mitbringt —, gilt das andere. Sonst stünde man vor einer
  /// leeren Seite und einem Knopf, der nichts ändert.
  Subject get subject =>
      _hatInhalt(_subject) ? _subject : _anderes(_subject);

  /// Ob ein Fach überhaupt etwas zu bieten hat.
  bool hasContent(Subject subject) => _hatInhalt(subject);

  bool _hatInhalt(Subject subject) =>
      _content.groups.any((CategoryGroup g) => Subject.of(g) == subject);

  static Subject _anderes(Subject subject) => subject == Subject.arabisch
      ? Subject.wissen
      : Subject.arabisch;

  Future<void> setSubject(Subject subject) async {
    if (_subject == subject) return;
    _subject = subject;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(subjectKey, subject.id);
  }

  /// Die Bereiche des aktiven Fachs — das, was die Startseite zeigt.
  List<CategoryGroup> get groups => groupsOf(subject);

  List<CategoryGroup> groupsOf(Subject subject) => <CategoryGroup>[
        for (final CategoryGroup g in _content.groups)
          if (Subject.of(g) == subject) g,
      ];

  /// Der Vorrat des aktiven Fachs — die Grundlage jeder Übung.
  List<VocabEntry> get activeEntries => entriesOf(subject);

  List<VocabEntry> entriesOf(Subject subject) => <VocabEntry>[
        for (final CategoryGroup g in groupsOf(subject)) ...g.entries,
      ];

  /// Der Inhalt hat sich geändert — etwa weil eine Karte gemerkt wurde.
  ///
  /// Die Registry liest die gemerkten Karten bei jedem Zugriff neu; ohne
  /// diesen Anstoß würde die Startseite die neue Karte aber erst beim
  /// nächsten Start zeigen.
  void contentChanged() => notifyListeners();

  final Map<String, WordProgress> _words = <String, WordProgress>{};
  Map<String, int> _history = <String, int>{};

  bool _loaded = false;
  int _answered = 0;
  int _correct = 0;
  int _sessionStreak = 0;
  int _bestStreak = 0;
  int _dailyGoal = 10;
  int _xp = 0;
  int _perfectRounds = 0;
  int _goalDays = 0;
  int _freezes = 0;
  Set<String> _frozenDays = <String>{};
  int _shortsDone = 0;
  int _questDays = 0;
  int _freezesEarned = 0;
  Set<ExerciseKind> _sessionKinds = ExerciseKind.values.toSet();
  int _sessionBlocks = kBlocksPerSession;
  int _blockSize = kDefaultBlockSize;

  /// Wohin gemeldet wird, was gerade passiert ist.
  ///
  /// Jede Antwort läuft ohnehin durch [recordAnswer] — hier hängen die
  /// Tagesaufgaben an **einer** Stelle statt an acht Übungsbildschirmen.
  /// Der Lernkern kennt dabei keinen Speicher, nur einen Rückruf.
  void Function(QuestKind kind, int amount)? _questReporter;

  /// Verbindet die Tagesaufgaben mit dem Lernkern. Einmal beim Start.
  void attachQuests(void Function(QuestKind kind, int amount) reporter) =>
      _questReporter = reporter;

  void _melde(QuestKind kind, [int amount = 1]) =>
      _questReporter?.call(kind, amount);

  bool get isLoaded => _loaded;
  int get answered => _answered;
  int get correct => _correct;

  /// Correct answers in a row within this session.
  int get streak => _sessionStreak;
  int get bestStreak => _bestStreak;

  int get dailyGoal => _dailyGoal;
  /// Wörter im aktiven Fach.
  int get totalCount => activeEntries.length;

  /// Alles, was die App kennt — für die Abzeichen, die vom Fach unabhängig
  /// sind.
  int get totalCountOverall => _content.entries.length;

  // ---- Punkte und Level -------------------------------------------------

  /// Punkte je Antwort und für ein erreichtes Tagesziel.
  static const int xpPerCorrect = 10;
  static const int xpPerWrong = 2;
  static const int xpPerGoal = 50;

  int get xp => _xp;
  int get perfectRounds => _perfectRounds;
  int get goalDays => _goalDays;

  /// Level 1 ab 0 Punkten, danach quadratisch steigender Bedarf: Level 2 ab
  /// 100, Level 3 ab 400, Level 4 ab 900 Punkten.
  int get level => 1 + (sqrt(_xp / 100)).floor();

  int get xpForCurrentLevel => _xpForLevel(level);
  int get xpForNextLevel => _xpForLevel(level + 1);

  static int _xpForLevel(int level) => 100 * (level - 1) * (level - 1);

  /// Fortschritt innerhalb des aktuellen Levels, 0 bis 1.
  double get levelProgress {
    final int span = xpForNextLevel - xpForCurrentLevel;
    if (span <= 0) return 1;
    return ((_xp - xpForCurrentLevel) / span).clamp(0, 1).toDouble();
  }

  /// Eine Runde ohne Fehler — zählt für das Abzeichen "Fehlerfrei".
  void recordPerfectRound() {
    _perfectRounds++;
    _xp += 25;
    _melde(QuestKind.fehlerfrei);
    notifyListeners();
    unawaited(_persist());
  }

  // ---- Abzeichen --------------------------------------------------------

  int _lessonsDone = 0;
  int _topicsUnderstood = 0;

  /// Der Lektionsfortschritt liegt in einem eigenen Speicher; der Lernkern
  /// bekommt ihn gemeldet, statt ihn zu kennen. So bleibt er von den
  /// Wissensdaten unabhängig — wie schon von den arabischen.
  void reportLessons({required int done, required int topicsUnderstood}) {
    if (_lessonsDone == done && _topicsUnderstood == topicsUnderstood) return;
    _lessonsDone = done;
    _topicsUnderstood = topicsUnderstood;
    notifyListeners();
  }

  /// Die Abzeichen hängen **nicht** am Fach: Wer umschaltet, hat nichts
  /// verlernt. Deshalb zählen hier die Werte über beide Fächer.
  AchievementStats get achievementStats => AchievementStats(
        learnedWords: learnedCountOverall,
        dayStreak: dayStreak,
        answers: _answered,
        perfectRounds: _perfectRounds,
        completedCategories: _content.categories
            .where((VocabCategory c) =>
                c.entries.isNotEmpty && c.entries.every(isLearned))
            .length,
        learnedQuranWords: _content
                .categoryById(AppContent.quranCategoryId)
                ?.entries
                .where(isLearned)
                .length ??
            0,
        level: level,
        lessonsDone: _lessonsDone,
        topicsUnderstood: _topicsUnderstood,
        shortsDone: _shortsDone,
        questDays: _questDays,
        freezesEarned: _freezesEarned,
      );

  List<Achievement> get unlockedAchievements {
    final AchievementStats stats = achievementStats;
    return kAchievements
        .where((Achievement a) => a.isUnlocked(stats))
        .toList();
  }

  static const int maxBox = WordProgress.maxBox;

  /// Loads the stored progress. Safe to call more than once.
  Future<void> load() async {
    final StoredProgress stored = await _store.load();
    _words
      ..clear()
      ..addAll(stored.words);
    _history = Map<String, int>.of(stored.history);
    _answered = stored.answered;
    _correct = stored.correct;
    _bestStreak = stored.bestStreak;
    _dailyGoal = stored.dailyGoal;
    _xp = stored.xp;
    _perfectRounds = stored.perfectRounds;
    _goalDays = stored.goalDays;
    _freezes = stored.freezes;
    _frozenDays = Set<String>.of(stored.frozenDays);
    _shortsDone = stored.shortsDone;
    _questDays = stored.questDays;
    _freezesEarned = stored.freezesEarned;
    // Leer heißt alle: Eine Installation von vor dieser Einstellung soll
    // keine Kurzrunde ohne Inhalt bekommen.
    final Set<ExerciseKind> gewaehlt = <ExerciseKind>{
      for (final String id in stored.sessionKinds)
        if (ExerciseKind.byId(id) case final ExerciseKind k) k,
    };
    _sessionKinds =
        gewaehlt.isEmpty ? ExerciseKind.values.toSet() : gewaehlt;
    _sessionBlocks = stored.sessionBlocks > 0
        ? stored.sessionBlocks
        : kBlocksPerSession;
    _blockSize =
        stored.blockSize > 0 ? stored.blockSize : kDefaultBlockSize;
    // Beim Öffnen wird nachgeholt, was seit dem letzten Mal liegen blieb:
    // Eine Lücke von gestern wird geschlossen, solange Joker da sind.
    _spendFreezes();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _subject = Subject.byId(prefs.getString(subjectKey)) ?? Subject.arabisch;

    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _store.save(StoredProgress(
        words: _words,
        answered: _answered,
        correct: _correct,
        bestStreak: _bestStreak,
        dailyGoal: _dailyGoal,
        history: _history,
        xp: _xp,
        perfectRounds: _perfectRounds,
        goalDays: _goalDays,
        freezes: _freezes,
        frozenDays: _frozenDays,
        shortsDone: _shortsDone,
        questDays: _questDays,
        freezesEarned: _freezesEarned,
        sessionKinds: <String>[
          for (final ExerciseKind k in _sessionKinds) k.id,
        ],
        sessionBlocks: _sessionBlocks,
        blockSize: _blockSize,
      ));

  /// Wirft die Lernstufen zu Karten weg, die es nicht mehr gibt.
  ///
  /// Gebraucht von den Tagesfunden: Über der Grenze fallen die ältesten
  /// Karten weg. Bliebe ihr Lernstand liegen, wüchse `_words` still weiter —
  /// Jahr für Jahr mit Einträgen zu Karten, die niemand mehr sieht.
  Future<void> forget(Iterable<String> ids) async {
    int weg = 0;
    for (final String id in ids) {
      if (_words.remove(id) != null) weg++;
    }
    if (weg == 0) return;
    notifyListeners();
    await _persist();
  }

  WordProgress progressOfWord(VocabEntry entry) =>
      _words[entry.id] ?? WordProgress();

  int boxOf(VocabEntry entry) => progressOfWord(entry).box;

  bool isLearned(VocabEntry entry) => progressOfWord(entry).isLearned;

  bool isDue(VocabEntry entry) => progressOfWord(entry).isDue(_now());

  DateTime? dueDateOf(VocabEntry entry) => progressOfWord(entry).due;

  /// Gelernte Wörter im aktiven Fach.
  ///
  /// Nicht die Zahl aller gespeicherten Einträge: Sonst stünde beim Wechsel
  /// nach „Wissen" plötzlich „700 von 301 gelernt".
  int get learnedCount => activeEntries.where(isLearned).length;

  /// Über beide Fächer — die Grundlage der Abzeichen.
  int get learnedCountOverall =>
      _words.values.where((WordProgress w) => w.isLearned).length;

  int get startedCount => _words.values
      .where((WordProgress w) => w.box > 0 && !w.isLearned)
      .length;

  double get overallProgress =>
      totalCount == 0 ? 0 : learnedCount / totalCount;

  /// Words waiting for a repetition today — the heart of the daily routine.
  List<VocabEntry> dueEntries([List<VocabEntry>? pool]) {
    final DateTime now = _now();
    return <VocabEntry>[
      for (final VocabEntry entry in pool ?? activeEntries)
        if (progressOfWord(entry).isDue(now)) entry,
    ];
  }

  /// Fällige Wörter im aktiven Fach.
  int get dueCount => dueEntries().length;

  /// Fällige Wörter in einem bestimmten Fach.
  int dueCountIn(Subject subject) => dueEntries(entriesOf(subject)).length;

  /// **Wiederholungen**, die in einem Fach anstehen — angefangene Wörter,
  /// deren Termin gekommen ist.
  ///
  /// Das ist die Zahl für die Marke am anderen Fach. `dueCountIn` taugt dafür
  /// nicht: Ein nie angefasstes Wort gilt als fällig, die Marke zeigte auf
  /// einer frischen Installation also für immer „301" und sagte damit nichts.
  /// Ein vergessenes Wort ist dringend, ein noch nie gesehenes nicht.
  int repetitionsDueIn(Subject subject) =>
      repetitionsDue(entriesOf(subject)).length;

  /// Die **angefangenen** Einträge, deren Termin gekommen ist.
  ///
  /// Der Unterschied zu [dueEntries] entscheidet mehr, als er aussieht: Dort
  /// gilt auch ein nie angesehener Eintrag als fällig — für eine erste Runde
  /// richtig, für alles, was „Wiederholung" heißt, falsch. Sonst begönne auf
  /// einer frischen Installation jede Lektion mit dem Nachfassen von Stoff,
  /// den noch niemand gesehen hat.
  ///
  /// Angefangen heißt: Es gibt einen Termin. Nicht `box > 0` — eine falsche
  /// Antwort setzt auf Fach 0 zurück, angefangen ist der Eintrag trotzdem.
  List<VocabEntry> repetitionsDue([List<VocabEntry>? pool]) {
    final DateTime now = _now();
    return <VocabEntry>[
      for (final VocabEntry entry in pool ?? activeEntries)
        if (progressOfWord(entry).due != null &&
            progressOfWord(entry).isDue(now))
          entry,
    ];
  }

  /// Fällige Wörter über beide Fächer. Die Abenderinnerung nennt diese Zahl:
  /// Sie soll an das ganze Pensum erinnern, nicht an die Hälfte.
  int get dueCountTotal => dueEntries(_content.entries).length;

  /// Answers given today, and whether the daily goal is reached.
  int get answeredToday => _history[dayKey(_now())] ?? 0;

  bool get goalReached => answeredToday >= _dailyGoal;

  double get goalProgress =>
      _dailyGoal == 0 ? 1 : min(1, answeredToday / _dailyGoal);

  /// Ob ein Tag für die Serie zählt: Ziel erreicht — oder von einem
  /// Jokertag gehalten.
  bool _dayCounts(DateTime day) =>
      (_history[dayKey(day)] ?? 0) >= _dailyGoal ||
      _frozenDays.contains(dayKey(day));

  /// Consecutive days up to today in which the daily goal was reached.
  int get dayStreak {
    int streak = 0;
    DateTime day = dayOf(_now());
    // Today only breaks the streak once it is over, so a day that has not
    // reached the goal yet is simply skipped.
    if (!_dayCounts(day)) {
      day = day.subtract(const Duration(days: 1));
    }
    while (_dayCounts(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---- Jokertage --------------------------------------------------------

  /// Wie viele Jokertage höchstens auf Vorrat liegen.
  ///
  /// Drei. Mehr wären eine Versicherung gegen das Aufhören, und dann hieße
  /// „Serie" nichts mehr.
  static const int maxFreezes = 3;

  /// Wie viele Tage am Stück ein Vorrat überbrücken darf.
  static const int maxFrozenInARow = 3;

  int get freezes => _freezes;

  /// Ob die letzte Lücke von einem Jokertag gehalten wurde — dann steht es
  /// auf der Startseite, statt stillschweigend zu passieren.
  bool get streakWasSaved {
    final DateTime gestern = dayOf(_now()).subtract(const Duration(days: 1));
    return _frozenDays.contains(dayKey(gestern));
  }

  /// Schließt die Lücke unmittelbar vor heute, solange Joker da sind.
  ///
  /// **Die Grenzen sind der Punkt.** Ein Joker rettet einen vergessenen Tag,
  /// keine vergessene Woche: höchstens [maxFrozenInARow] Tage am Stück, nur
  /// direkt vor heute, und nur, wenn davor überhaupt eine Serie stand. Wer
  /// nach drei Monaten zurückkommt, verbraucht keinen einzigen — dort gibt
  /// es nichts zu halten.
  void _spendFreezes() {
    if (_freezes <= 0) return;

    final DateTime heute = dayOf(_now());
    // Die Lücke: Tage vor heute, die nicht zählen.
    final List<DateTime> luecke = <DateTime>[];
    DateTime tag = heute.subtract(const Duration(days: 1));
    while (luecke.length <= maxFrozenInARow && !_dayCounts(tag)) {
      luecke.add(tag);
      tag = tag.subtract(const Duration(days: 1));
    }

    // Keine Lücke, oder eine zu große: nichts zu tun. Bei einer zu großen
    // wären die Joker verschwendet, ohne dass eine Serie entstünde.
    if (luecke.isEmpty || luecke.length > maxFrozenInARow) return;
    if (luecke.length > _freezes) return;
    // `tag` steht jetzt auf dem letzten Tag vor der Lücke. Zählt der nicht,
    // gab es keine Serie, die zu halten wäre.
    if (!_dayCounts(tag)) return;

    for (final DateTime geschlossen in luecke) {
      _frozenDays.add(dayKey(geschlossen));
      _freezes--;
    }
  }

  // ---- Lernen in Blöcken -------------------------------------------------

  /// Wie viele Wörter ein Block umfasst.
  int get blockSize => _blockSize;

  Future<void> setBlockSize(int size) async {
    _blockSize = size.clamp(5, 50);
    notifyListeners();
    await _persist();
  }

  /// Die Wörter, an denen gerade gearbeitet wird.
  ///
  /// **Warum es das gibt.** Vorher stand auf der Startseite „793 Wörter
  /// warten auf eine Wiederholung" — weil ein nie angesehenes Wort als
  /// fällig gilt. Das ist keine Aufgabe, das ist eine Drohung, und sie wird
  /// über Monate nicht kleiner.
  ///
  /// Ein Block sind die nächsten [blockSize] Wörter des Lernwegs, die noch
  /// nicht sitzen. Man übt sie, bis sie sitzen; dann rückt der Block von
  /// selbst weiter. Es braucht dafür **nichts Gespeichertes**: Was sitzt,
  /// steht schon im Lernstand, und die Reihenfolge steht im Lernweg. Ein
  /// zweiter Merker wäre eine zweite Wahrheit, die irgendwann abweicht.
  List<VocabEntry> get currentBlock {
    final List<VocabEntry> offen = <VocabEntry>[
      for (final VocabEntry e in activeEntries)
        if (!isLearned(e)) e,
    ];
    return offen.take(min(_blockSize, offen.length)).toList();
  }

  /// Wie viele Wörter des laufenden Blocks schon sitzen.
  ///
  /// Immer 0, solange keines sitzt — der Block besteht ja gerade aus den
  /// noch offenen. Gezählt wird deshalb innerhalb der Blockgrenze des
  /// Lernwegs, nicht innerhalb von [currentBlock].
  int get blockLearned {
    final int gelernt = learnedCount;
    return gelernt - (gelernt ~/ _blockSize) * _blockSize;
  }

  /// Der wievielte Block gerade dran ist, ab 1.
  int get blockNumber => (learnedCount ~/ _blockSize) + 1;

  /// Wie viele Blöcke das aktive Fach insgesamt hat.
  int get blockCount => (totalCount + _blockSize - 1) ~/ _blockSize;

  /// Fortschritt im laufenden Block, 0 bis 1.
  double get blockProgress =>
      _blockSize == 0 ? 1 : (blockLearned / _blockSize).clamp(0, 1).toDouble();

  // ---- Kurzrunde nach Maß ------------------------------------------------

  /// Welche Übungsarten in einer Kurzrunde vorkommen dürfen.
  Set<ExerciseKind> get sessionKinds => Set<ExerciseKind>.unmodifiable(
        _sessionKinds.isEmpty ? ExerciseKind.values.toSet() : _sessionKinds,
      );

  /// Wie viele Blöcke eine Kurzrunde hat.
  int get sessionBlocks => _sessionBlocks;

  /// Setzt die Auswahl. **Eine Art bleibt immer übrig** — eine Kurzrunde
  /// ohne Übung wäre ein Knopf, der ins Leere führt.
  Future<void> setSessionKinds(Set<ExerciseKind> kinds) async {
    if (kinds.isEmpty) return;
    _sessionKinds = Set<ExerciseKind>.of(kinds);
    notifyListeners();
    await _persist();
  }

  Future<void> setSessionBlocks(int blocks) async {
    _sessionBlocks = blocks.clamp(1, 6);
    notifyListeners();
    await _persist();
  }

  int get shortsDone => _shortsDone;
  int get questDays => _questDays;
  int get freezesEarned => _freezesEarned;

  /// Ein Thema im Feed bis zum Ende durchgewischt.
  Future<void> recordShortsFinished() async {
    _shortsDone++;
    notifyListeners();
    await _persist();
  }

  /// Ein Tag, an dem alle drei Tagesaufgaben erledigt waren.
  ///
  /// Der Jokertag hängt daran: Er wird **verdient**, nicht geschenkt. Über
  /// dem Vorrat verfällt er — gezählt wird trotzdem nur, was wirklich
  /// dazukam, sonst stimmte das Abzeichen nicht mit der Zahl überein.
  Future<void> recordQuestDay() async {
    _questDays++;
    final bool bekommen = _freezes < maxFreezes;
    if (bekommen) {
      _freezes++;
      _freezesEarned++;
    }
    notifyListeners();
    await _persist();
  }

  /// Verdient einen Jokertag — für einen Tag, an dem alles erledigt wurde.
  ///
  /// Gibt zurück, ob wirklich einer dazukam: Über dem Vorrat verfällt er,
  /// und der Bildschirm soll nichts melden, was nicht passiert ist.
  Future<bool> earnFreeze() async {
    if (_freezes >= maxFreezes) return false;
    _freezes++;
    notifyListeners();
    await _persist();
    return true;
  }

  /// Answers per day for the last [days] days, oldest first.
  List<MapEntry<DateTime, int>> recentActivity({int days = 14}) {
    final DateTime today = dayOf(_now());
    return <MapEntry<DateTime, int>>[
      for (int i = days - 1; i >= 0; i--)
        () {
          final DateTime day = today.subtract(Duration(days: i));
          return MapEntry<DateTime, int>(day, _history[dayKey(day)] ?? 0);
        }(),
    ];
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal.clamp(1, 200);
    notifyListeners();
    await _persist();
  }

  void _update(VocabEntry entry, WordProgress next, {bool persist = true}) {
    _words[entry.id] = next;
    notifyListeners();
    if (persist) unawaited(_persist());
  }

  /// A correct answer: one box up, next repetition further away.
  void promote(VocabEntry entry) =>
      _update(entry, progressOfWord(entry).promote(_now()));

  /// A wrong answer: back to the first box, due again today.
  void demote(VocabEntry entry) =>
      _update(entry, progressOfWord(entry).demote(_now()));

  void markLearned(VocabEntry entry) => _update(
      entry, progressOfWord(entry).setBox(WordProgress.maxBox, _now()));

  void markUnlearned(VocabEntry entry) =>
      _update(entry, progressOfWord(entry).setBox(0, _now()));

  void toggleLearned(VocabEntry entry) {
    if (isLearned(entry)) {
      markUnlearned(entry);
    } else {
      markLearned(entry);
    }
  }

  int learnedIn(VocabCategory category) =>
      category.entries.where(isLearned).length;

  double progressOf(VocabCategory category) => category.entries.isEmpty
      ? 0
      : learnedIn(category) / category.entries.length;

  int dueIn(VocabCategory category) => dueEntries(category.entries).length;

  /// Gelernte Wörter eines Bereichs — die Startseite zeigt den Fortschritt
  /// bereichsweise statt als eine große Zahl über alles. Sonst fiele die
  /// Anzeige sichtbar ab, sobald ein neues Fach dazukommt, ohne dass jemand
  /// etwas verlernt hätte.
  int learnedInGroup(CategoryGroup group) =>
      group.entries.where(isLearned).length;

  double progressOfGroup(CategoryGroup group) {
    final int total = group.entries.length;
    return total == 0 ? 0 : learnedInGroup(group) / total;
  }

  int dueInGroup(CategoryGroup group) => dueEntries(group.entries).length;

  /// Wie viele Karten eine Tagesportion umfasst.
  ///
  /// Alle 1.100 Karten am Stück durchzugehen, schafft niemand — und wer es
  /// versucht, hört nach drei Tagen auf. Die Portion wächst mit dem
  /// Tagesziel: Wer sich mehr vornimmt, bekommt mehr.
  int get dosePerRound => (_dailyGoal * 2).clamp(10, 40);

  /// Die Karten für heute: fällige zuerst, dann die schwächsten — und nicht
  /// mehr, als in einer Sitzung zu schaffen ist.
  /// Woran heute gearbeitet wird: fällige Wiederholungen und der laufende
  /// Block — nicht der ganze Bestand.
  ///
  /// Vorher zog jede Übung aus allen 801 Wörtern. Man bekam ständig neue
  /// vorgesetzt und brachte keines zu Ende; genau daher kam die Zahl, die
  /// nie kleiner wurde.
  List<VocabEntry> get workingSet {
    final List<VocabEntry> faellig = repetitionsDue();
    final Set<String> drin = <String>{
      for (final VocabEntry e in faellig) e.id,
    };
    return <VocabEntry>[
      ...faellig,
      for (final VocabEntry e in currentBlock)
        if (drin.add(e.id)) e,
    ];
  }

  List<VocabEntry> dailySelection({
    List<VocabEntry>? pool,
    int? size,
    Random? random,
  }) {
    final List<VocabEntry> quelle = pool ?? workingSet;
    // Ein leerer Block heißt: alles sitzt. Dann darf eine Übung wieder aus
    // dem ganzen Fach ziehen, statt ins Leere zu greifen.
    final List<VocabEntry> ordered = trainingOrder(
        quelle.isEmpty ? activeEntries : quelle,
        random: random);
    return ordered.take(min(size ?? dosePerRound, ordered.length)).toList();
  }

  /// Training order: what is due comes first, then the weakest boxes,
  /// shuffled inside a group so a round never feels the same twice.
  List<VocabEntry> trainingOrder(List<VocabEntry> pool, {Random? random}) {
    final DateTime now = _now();
    final Random rnd = random ?? Random();
    final List<VocabEntry> shuffled = List<VocabEntry>.of(pool)..shuffle(rnd);
    shuffled.sort((VocabEntry a, VocabEntry b) {
      final WordProgress pa = progressOfWord(a);
      final WordProgress pb = progressOfWord(b);
      final int dueOrder = (pb.isDue(now) ? 1 : 0) - (pa.isDue(now) ? 1 : 0);
      if (dueOrder != 0) return dueOrder;
      return pa.box.compareTo(pb.box);
    });
    return shuffled;
  }

  void recordAnswer({required bool correct}) {
    // Erst die Lücke schließen, dann heute zählen: Wer nach einem
    // verpassten Tag wieder anfängt, soll die gehaltene Serie sehen und
    // nicht erst beim nächsten Start.
    _spendFreezes();
    final bool goalWasReached = goalReached;

    _answered++;
    _xp += correct ? xpPerCorrect : xpPerWrong;
    if (correct) {
      _correct++;
      _sessionStreak++;
      _bestStreak = max(_bestStreak, _sessionStreak);
    } else {
      _sessionStreak = 0;
    }
    final String key = dayKey(_now());
    _history[key] = (_history[key] ?? 0) + 1;

    _melde(QuestKind.antworten);
    if (correct) _melde(QuestKind.richtige);

    // Der Moment, in dem das Tagesziel fällt: einmalig Punkte und ein Tag
    // mehr auf dem Konto.
    if (!goalWasReached && goalReached) {
      _xp += xpPerGoal;
      _goalDays++;
    }

    notifyListeners();
    unawaited(_persist());
  }

  Future<void> reset() async {
    _words.clear();
    _history = <String, int>{};
    _answered = 0;
    _correct = 0;
    _sessionStreak = 0;
    _bestStreak = 0;
    _xp = 0;
    _perfectRounds = 0;
    _goalDays = 0;
    _freezes = 0;
    _frozenDays = <String>{};
    _shortsDone = 0;
    _questDays = 0;
    _freezesEarned = 0;
    _sessionKinds = ExerciseKind.values.toSet();
    _sessionBlocks = kBlocksPerSession;
    _blockSize = kDefaultBlockSize;
    notifyListeners();
    await _store.clear();
  }
}

/// Makes the [LearningState] available to the whole widget tree.
class LearningScope extends InheritedNotifier<LearningState> {
  const LearningScope({
    super.key,
    required LearningState state,
    required super.child,
  }) : super(notifier: state);

  static LearningState of(BuildContext context) {
    final LearningScope? scope =
        context.dependOnInheritedWidgetOfExactType<LearningScope>();
    assert(scope != null, 'No LearningScope found in the widget tree');
    return scope!.notifier!;
  }
}
