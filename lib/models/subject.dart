import 'package:flutter/material.dart';

import 'vocabulary.dart';

/// Ein Fach der App.
///
/// Es ist immer genau eines aktiv. „Alles" gibt es bewusst nicht: Eine Runde
/// aus Vokabeln und Wissensfragen durcheinander lernt sich schlechter als
/// zehn Minuten in einer Sache — und die Wahl kostet einen Griff, nicht drei.
enum Subject {
  arabisch,
  wissen;

  String get label => switch (this) {
        Subject.arabisch => 'Arabisch',
        Subject.wissen => 'Wissen',
      };

  IconData get icon => switch (this) {
        Subject.arabisch => Icons.translate,
        Subject.wissen => Icons.lightbulb_outline,
      };

  IconData get selectedIcon => switch (this) {
        Subject.arabisch => Icons.translate,
        Subject.wissen => Icons.lightbulb,
      };

  /// Für die Speicherung. Nicht `index` — eine spätere Umsortierung des
  /// enums würde sonst den gespeicherten Wert umdeuten.
  String get id => name;

  static Subject? byId(String? id) {
    for (final Subject subject in Subject.values) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  /// Zu welchem Fach ein Bereich gehört.
  ///
  /// Abgelesen statt gepflegt: `knowledge_data_test.dart` prüft bereits, dass
  /// jeder Bereich entweder ganz Sprache oder ganz Wissen ist. Ein leerer
  /// Bereich — den es nicht geben sollte — zählt zu Wissen.
  static Subject of(CategoryGroup group) =>
      group.isLanguage ? Subject.arabisch : Subject.wissen;
}
