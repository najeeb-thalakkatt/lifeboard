import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lifeboard/theme/app_colors.dart';

/// Lifeboard typography built on Nunito (headings) + Inter (body).
abstract final class AppTextStyles {
  // ── Headings (Nunito Bold) ───────────────────────────────

  static TextStyle headingLarge = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle headingMedium = GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle headingSmall = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // ── Body (Inter Regular) ─────────────────────────────────

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  // ── Caption (Inter Regular) ──────────────────────────────

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  // ── Button (Inter SemiBold) ──────────────────────────────

  static TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );

  // ── Light-on-dark variants ───────────────────────────────

  static TextStyle headingLargeLight = headingLarge.copyWith(
    color: AppColors.textSecondary,
  );

  static TextStyle bodyLargeLight = bodyLarge.copyWith(
    color: AppColors.textSecondary,
  );
}
