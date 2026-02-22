import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available themes for MyFlashCards.
enum AppThemeType {
  // ── Adult themes ───────────────────────────────────────────────────────────
  /// Deep indigo and violet — the original default.
  classic,

  /// Bold ocean blues and cyan — energetic, sporty feel.
  oceanBlue,

  /// Soft roses and warm lilac — elegant, playful feel.
  roseGarden,

  /// Slate and teal — clean, distraction-free, corporate feel.
  executive,

  // ── Kids themes ────────────────────────────────────────────────────────────
  /// Bright sunshine yellow and hot coral — sunny, cheerful.
  sunshine,

  /// Lime green and sky blue — outdoorsy, fresh, adventure vibes.
  jungle,

  /// Vivid magenta and bright purple — bubbly, candy-shop feel.
  bubblegum,

  /// Orange and electric blue — bold superhero energy.
  superHero,
}

/// Whether a given theme belongs to the kids palette.
extension AppThemeTypeX on AppThemeType {
  bool get isKids => index >= AppThemeType.sunshine.index;
  bool get isAdult => !isKids;
}

class AppTheme {
  // ── Seed colours per theme ─────────────────────────────────────────────────

  static const _seeds = {
    AppThemeType.classic: (
      primary: Color(0xFF4F46E5),
      secondary: Color(0xFF7C3AED),
    ),
    AppThemeType.oceanBlue: (
      primary: Color(0xFF0369A1),
      secondary: Color(0xFF0891B2),
    ),
    AppThemeType.roseGarden: (
      primary: Color(0xFFBE185D),
      secondary: Color(0xFF9333EA),
    ),
    AppThemeType.executive: (
      primary: Color(0xFF0F766E),
      secondary: Color(0xFF334155),
    ),
    // Kids ──────────────────────────────────────────────────────────────────
    AppThemeType.sunshine: (
      primary: Color(0xFFD97706), // Amber-600
      secondary: Color(0xFFEF4444), // Red-500 (coral)
    ),
    AppThemeType.jungle: (
      primary: Color(0xFF16A34A), // Green-600
      secondary: Color(0xFF0284C7), // Sky-600
    ),
    AppThemeType.bubblegum: (
      primary: Color(0xFFDB2777), // Pink-600
      secondary: Color(0xFF9333EA), // Purple-600
    ),
    AppThemeType.superHero: (
      primary: Color(0xFFEA580C), // Orange-600
      secondary: Color(0xFF2563EB), // Blue-600
    ),
  };

  static const _fonts = {
    AppThemeType.classic: 'Inter',
    AppThemeType.oceanBlue: 'Nunito',
    AppThemeType.roseGarden: 'Lato',
    AppThemeType.executive: 'IBM Plex Sans',
    // Kids use rounded, playful fonts
    AppThemeType.sunshine: 'Nunito',
    AppThemeType.jungle: 'Nunito',
    AppThemeType.bubblegum: 'Nunito',
    AppThemeType.superHero: 'Nunito',
  };

  // ── Public builders ────────────────────────────────────────────────────────

  static ThemeData light([AppThemeType type = AppThemeType.classic]) =>
      _build(type, Brightness.light);

  static ThemeData dark([AppThemeType type = AppThemeType.classic]) =>
      _build(type, Brightness.dark);

  // ── Internal builder ───────────────────────────────────────────────────────

  static ThemeData _build(AppThemeType type, Brightness brightness) {
    final seed = _seeds[type]!;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed.primary,
      secondary: seed.secondary,
      brightness: brightness,
    );

    final baseText = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final textTheme = switch (_fonts[type]!) {
      'Nunito' => GoogleFonts.nunitoTextTheme(baseText),
      'Lato' => GoogleFonts.latoTextTheme(baseText),
      'IBM Plex Sans' => GoogleFonts.ibmPlexSansTextTheme(baseText),
      _ => GoogleFonts.interTextTheme(baseText),
    };

    // Kids themes get extra-rounded corners to feel friendly.
    final radius = type.isKids ? 20.0 : 16.0;

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
        ),
        filled: true,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius - 4),
        ),
      ),
    );
  }
}
