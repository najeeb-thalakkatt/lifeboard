import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lifeboard typography built on Nunito (headings) + Inter (body).
///
/// Colors are intentionally omitted — text color comes from the theme
/// (light or dark) via [ThemeData.textTheme] and [ColorScheme.onSurface].
/// Use `.copyWith(color: ...)` when you need an explicit override.
abstract final class AppTextStyles {
  // ── Headings (Nunito Bold) ───────────────────────────────

  static TextStyle headingLarge = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static TextStyle headingMedium = GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle headingSmall = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  // ── Body (Inter Regular) ─────────────────────────────────

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  // ── Caption (Inter Regular) ──────────────────────────────

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // ── Button (Inter SemiBold) ──────────────────────────────

  static TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
