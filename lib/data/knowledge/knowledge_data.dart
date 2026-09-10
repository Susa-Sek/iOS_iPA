import 'package:flutter/material.dart';

import '../../models/vocabulary.dart';
import 'allgemeinbildung.dart';
import 'gesellschaft.dart';
import 'technik.dart';

/// Alle Wissensthemen, quer über die drei Fächer.
///
/// Sie bleiben bewusst getrennt von `kAllCategories`: `vocabulary_data_test`
/// fordert für jeden Eintrag dort arabische Schrift, `curriculum_test`, dass
/// `kGroups` genau den arabischen Bestand abdeckt. Zusammengeführt wird erst
/// eine Ebene höher, in der Registry.
List<VocabCategory> get kKnowledgeCategories => <VocabCategory>[
      ...kAllgemeinbildung,
      ...kTechnik,
      ...kGesellschaft,
    ];

List<VocabEntry> get kKnowledgeEntries => <VocabEntry>[
      for (final VocabCategory c in kKnowledgeCategories) ...c.entries,
    ];

/// Die drei Fächer als Bereiche des Lernwegs — in derselben Form wie
/// `kGroups` für den Wortschatz.
List<CategoryGroup> get kKnowledgeGroups => <CategoryGroup>[
      const CategoryGroup(
        id: 'wissen_allgemein',
        name: 'Allgemeinbildung',
        description: 'Erde, Geschichte, Natur, Kunst und Zahlen.',
        icon: Icons.lightbulb_outline,
        categories: kAllgemeinbildung,
      ),
      const CategoryGroup(
        id: 'wissen_technik',
        name: 'Technik & Digitales',
        description: 'Was man täglich benutzt, ohne es zu kennen.',
        icon: Icons.memory_outlined,
        categories: kTechnik,
      ),
      const CategoryGroup(
        id: 'wissen_gesellschaft',
        name: 'Politik, Wirtschaft, Gesellschaft',
        description: 'Die Regeln, nach denen das Zusammenleben läuft.',
        icon: Icons.account_balance_outlined,
        categories: kGesellschaft,
      ),
    ];
