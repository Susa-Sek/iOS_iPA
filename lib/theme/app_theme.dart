import 'package:flutter/material.dart';

/// Ein gemeinsames Raster für die ganze App.
///
/// Vorher wurden Abstände, Radien und Schriftgrößen pro Bildschirm geraten —
/// mal 12, mal 14, mal 16 Pixel. Diese Konstanten geben einen Takt vor, an
/// dem sich alles ausrichtet; das ist der Unterschied zwischen „funktioniert"
/// und „wirkt aus einem Guss".
abstract final class Insets {
  /// Vier-Punkt-Raster: alle Abstände sind Vielfache davon.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Seitenrand für Inhalte.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);

  /// Innenabstand einer Karte.
  static const EdgeInsets card = EdgeInsets.all(lg);
}

abstract final class Radii {
  static const double card = 16;
  static const double chip = 12;
  static const double bar = 4;

  static const BorderRadius cardShape = BorderRadius.all(Radius.circular(card));
  static const BorderRadius chipShape = BorderRadius.all(Radius.circular(chip));
}

/// Kleinste Tippfläche nach den Android- und iOS-Richtlinien.
const double kMinTapTarget = 48;

/// Dauer für die kurzen Übergänge in den Übungen.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

/// Farben für Rückmeldungen, die in beiden Themen lesbar bleiben.
abstract final class Feedback {
  static const Color correct = Color(0xFF2E7D32);
  static const Color correctDark = Color(0xFF66BB6A);

  static Color right(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? correctDark : correct;
}

/// Das Erscheinungsbild der App.
ThemeData buildAppTheme(Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1F7A6C),
    brightness: brightness,
  );
  final bool light = brightness == Brightness.light;

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor:
        light ? const Color(0xFFF7F6F2) : scheme.surface,
    // Karten überall gleich: ruhige Kante statt Schattenstapel.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: light ? Colors.white : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.cardShape,
        side: BorderSide(
          color: light
              ? const Color(0x14000000)
              : const Color(0x1FFFFFFF),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: light ? const Color(0xFFF7F6F2) : scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0.5,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kMinTapTarget),
        shape: const RoundedRectangleBorder(borderRadius: Radii.chipShape),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kMinTapTarget),
        shape: const RoundedRectangleBorder(borderRadius: Radii.chipShape),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: Insets.md,
    ),
    dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: scheme.primaryContainer,
      linearMinHeight: 6,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 2,
      backgroundColor: light ? Colors.white : scheme.surfaceContainerHigh,
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
