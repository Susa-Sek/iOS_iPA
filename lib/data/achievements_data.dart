import 'package:flutter/material.dart';

import '../models/achievement.dart';

/// The badges, roughly in the order they are reached.
const List<Achievement> kAchievements = <Achievement>[
  Achievement(
    id: 'first_ten',
    name: 'Angefangen',
    description: '10 Wörter gelernt',
    icon: Icons.spa_outlined,
    target: 10,
    progress: _learned,
  ),
  Achievement(
    id: 'streak_3',
    name: 'Dranbleiber',
    description: '3 Tage in Folge das Tagesziel geschafft',
    icon: Icons.local_fire_department_outlined,
    target: 3,
    progress: _streak,
  ),
  Achievement(
    id: 'answers_100',
    name: 'Fleißig',
    description: '100 Antworten gegeben',
    icon: Icons.touch_app_outlined,
    target: 100,
    progress: _answers,
  ),
  Achievement(
    id: 'words_50',
    name: 'Grundstock',
    description: '50 Wörter sitzen',
    icon: Icons.eco_outlined,
    target: 50,
    progress: _learned,
  ),
  Achievement(
    id: 'perfect_round',
    name: 'Fehlerfrei',
    description: 'Eine Quizrunde ohne einen Fehler',
    icon: Icons.check_circle_outline,
    target: 1,
    progress: _perfect,
  ),
  Achievement(
    id: 'streak_7',
    name: 'Eine Woche',
    description: '7 Tage in Folge gelernt',
    icon: Icons.calendar_view_week_outlined,
    target: 7,
    progress: _streak,
  ),
  Achievement(
    id: 'category_done',
    name: 'Thema gemeistert',
    description: 'Ein ganzes Thema gelernt',
    icon: Icons.workspace_premium_outlined,
    target: 1,
    progress: _categories,
  ),
  Achievement(
    id: 'words_200',
    name: 'Wortsammler',
    description: '200 Wörter sitzen',
    icon: Icons.library_books_outlined,
    target: 200,
    progress: _learned,
  ),
  Achievement(
    id: 'quran_25',
    name: 'Quran-Einstieg',
    description: '25 der häufigsten Quran-Wörter gelernt',
    icon: Icons.menu_book_outlined,
    target: 25,
    progress: _quran,
  ),
  Achievement(
    id: 'streak_30',
    name: 'Ein Monat',
    description: '30 Tage in Folge gelernt',
    icon: Icons.emoji_events_outlined,
    target: 30,
    progress: _streak,
  ),
  Achievement(
    id: 'level_10',
    name: 'Stufe 10',
    description: 'Level 10 erreicht',
    icon: Icons.military_tech_outlined,
    target: 10,
    progress: _level,
  ),
  Achievement(
    id: 'words_400',
    name: 'Halbzeit',
    description: '400 Wörter sitzen',
    icon: Icons.star_outline,
    target: 400,
    progress: _learned,
  ),

  // ---- Wissen -----------------------------------------------------------
  //
  // Eigene Abzeichen, weil dort anders gelernt wird. Ein Wort ist gelernt
  // oder nicht; ein Thema ist verstanden, wenn man es durchgearbeitet hat.
  Achievement(
    id: 'erste_lektion',
    name: 'Erste Lektion',
    description: 'Eine Lektion durchgearbeitet',
    icon: Icons.menu_book_outlined,
    target: 1,
    progress: _lessons,
  ),
  Achievement(
    id: 'thema_verstanden',
    name: 'Verstanden',
    description: 'Ein Thema ganz durchgearbeitet',
    icon: Icons.psychology_outlined,
    target: 1,
    progress: _topics,
  ),
  Achievement(
    id: 'zehn_lektionen',
    name: 'Belesen',
    description: '10 Lektionen durchgearbeitet',
    icon: Icons.auto_stories_outlined,
    target: 10,
    progress: _lessons,
  ),
  Achievement(
    id: 'fuenf_themen',
    name: 'Weitgereist',
    description: '5 Themen verstanden',
    icon: Icons.explore_outlined,
    target: 5,
    progress: _topics,
  ),

  // ---- Feed, Tagesaufgaben und Jokertage --------------------------------
  //
  // Drei Wege, die es vorher nicht gab. Ein Abzeichen für jeden, damit
  // sichtbar wird, dass sie zählen — und nicht nur Beiwerk sind.
  Achievement(
    id: 'erstes_thema_gewischt',
    name: 'Durchgewischt',
    description: 'Ein Thema im Feed bis zum Ende',
    icon: Icons.swipe_up_alt_outlined,
    target: 1,
    progress: _shorts,
  ),
  Achievement(
    id: 'zehn_themen_gewischt',
    name: 'Zwischendurch',
    description: '10 Themen durchgewischt',
    icon: Icons.swipe_outlined,
    target: 10,
    progress: _shorts,
  ),
  Achievement(
    id: 'erster_voller_tag',
    name: 'Alles erledigt',
    description: 'Alle drei Tagesaufgaben an einem Tag',
    icon: Icons.checklist_rtl,
    target: 1,
    progress: _questDays,
  ),
  Achievement(
    id: 'sieben_volle_tage',
    name: 'Gründlich',
    description: 'An 7 Tagen alle Tagesaufgaben',
    icon: Icons.task_alt,
    target: 7,
    progress: _questDays,
  ),
  Achievement(
    id: 'erster_joker',
    name: 'Vorgesorgt',
    description: 'Einen Jokertag verdient',
    icon: Icons.ac_unit,
    target: 1,
    progress: _freezes,
  ),
  Achievement(
    id: 'drei_joker',
    name: 'Gut gewappnet',
    description: '3 Jokertage verdient',
    icon: Icons.shield_outlined,
    target: 3,
    progress: _freezes,
  ),
];

int _learned(AchievementStats s) => s.learnedWords;
int _streak(AchievementStats s) => s.dayStreak;
int _answers(AchievementStats s) => s.answers;
int _perfect(AchievementStats s) => s.perfectRounds;
int _categories(AchievementStats s) => s.completedCategories;
int _quran(AchievementStats s) => s.learnedQuranWords;
int _level(AchievementStats s) => s.level;
int _lessons(AchievementStats s) => s.lessonsDone;
int _topics(AchievementStats s) => s.topicsUnderstood;
int _shorts(AchievementStats s) => s.shortsDone;
int _questDays(AchievementStats s) => s.questDays;
int _freezes(AchievementStats s) => s.freezesEarned;
