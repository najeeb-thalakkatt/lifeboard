import 'package:flutter/material.dart';

/// Lifeboard brand color palette.
///
/// All colors sourced from the brand identity guide.
abstract final class AppColors {
  // ── Primary ──────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF2F6264);
  static const Color primaryLight = Color(0xFFE2EAEB);

  // ── Background & Surface ─────────────────────────────────
  static const Color background = Color(0xFF77B5B3);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Accent ───────────────────────────────────────────────
  static const Color accentWarm = Color(0xFFF5A623);

  // ── Semantic ─────────────────────────────────────────────
  static const Color error = Color(0xFFD94F4F);

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2F6264);
  static const Color textSecondary = Color(0xFFE2EAEB);

  // ── Convenience ──────────────────────────────────────────
  static const Color cardShadow = Color(0x1A000000); // 10% black
  static const Color divider = Color(0xFFE0E0E0);
}
