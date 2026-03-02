import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lifeboard typography built on Nunito (headings) + Inter (body).
///
/// Colors are intentionally omitted — text color comes from the theme
/// (light or dark) via [ThemeData.textTheme] and [ColorScheme.onSurface].
/// Use `.copyWith(color: ...)` when you need an explicit override.
abstract final class AppTextStyles {
  // ── Headings (Nunito Bold) ───────────────────────────────

  static final TextStyle headingLarge = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle headingMedium = GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle headingSmall = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  // ── Body (Inter Regular) ─────────────────────────────────

  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  // ── Caption (Inter Regular) ──────────────────────────────

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // ── Button (Inter SemiBold) ──────────────────────────────

  static final TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
