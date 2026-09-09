import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import 'quran_vocab.dart';
import 'vocabulary_data.dart';
import 'vocabulary_more.dart';

/// Findet eine Kategorie über ihre id — so bleibt der Lernweg unabhängig
/// davon, in welcher Datei eine Kategorie steht.
VocabCategory _byId(String id) => <VocabCategory>[
      ...kCategories,
      ...kMoreCategories,
      kQuranWords,
    ].firstWhere((VocabCategory c) => c.id == id,
        orElse: () => throw StateError('Unbekannte Kategorie: $id'));

/// Der Lernweg: sechs Bereiche in der Reihenfolge, in der man sie sinnvoll
/// durchgeht. Jede Kategorie steht in genau einem Bereich.
List<CategoryGroup> get kGroups => <CategoryGroup>[
      CategoryGroup(
        id: 'start',
        name: 'Erste Schritte',
        description: 'Die Wörter, mit denen jedes Gespräch anfängt.',
        icon: Icons.flag_outlined,
        categories: <VocabCategory>[
          _byId('allgemein'),
          _byId('begruessung'),
          _byId('vorstellung'),
          _byId('zahlen'),
          _byId('pronomen'),
        ],
      ),
      CategoryGroup(
        id: 'alltag',
        name: 'Alltag',
        description: 'Was zu Hause, beim Einkaufen und am Tag vorkommt.',
        icon: Icons.home_outlined,
        categories: <VocabCategory>[
          _byId('zeit'),
          _byId('farben'),
          _byId('familie'),
          _byId('essen'),
          _byId('wohnen'),
          _byId('kleidung'),
          _byId('einkaufen'),
        ],
      ),
      CategoryGroup(
        id: 'unterwegs',
        name: 'Unterwegs',
        description: 'Reisen, den Weg finden, Restaurant und Hotel.',
        icon: Icons.explore_outlined,
        categories: <VocabCategory>[
          _byId('reise'),
          _byId('wege'),
          _byId('orte'),
          _byId('restaurant'),
          _byId('hotel'),
        ],
      ),
      CategoryGroup(
        id: 'welt',
        name: 'Mensch & Welt',
        description: 'Körper, Gesundheit, Gefühle, Arbeit, Natur und Technik.',
        icon: Icons.public,
        categories: <VocabCategory>[
          _byId('koerper'),
          _byId('gesundheit'),
          _byId('gefuehle'),
          _byId('beruf'),
          _byId('schule'),
          _byId('tiere'),
          _byId('natur'),
          _byId('sport'),
          _byId('technik'),
        ],
      ),
      CategoryGroup(
        id: 'bausteine',
        name: 'Bausteine der Sprache',
        description: 'Verben, Adjektive und die kleinen Wörter, die alles '
            'zusammenhalten.',
        icon: Icons.extension_outlined,
        categories: <VocabCategory>[
          _byId('woerter'),
          _byId('verben'),
          _byId('verben2'),
          _byId('adjektive'),
          _byId('gegenteile'),
          _byId('mengen'),
        ],
      ),
      CategoryGroup(
        id: 'quran',
        name: 'Quran-Sprache',
        description: 'Die häufigsten Wörter des Quran.',
        icon: Icons.menu_book_outlined,
        categories: <VocabCategory>[
          _byId('quran_woerter'),
        ],
      ),
    ];
