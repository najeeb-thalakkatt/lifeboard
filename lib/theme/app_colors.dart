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

  // ── Status Accents ──────────────────────────────────────
  static const Color statusTodo = Color(0xFF2F6264);
  static const Color statusInProgress = Color(0xFFF5A623);
  static const Color statusDone = Color(0xFF4CAF50);

  /// Returns the accent color for a task status key.
  static Color statusAccent(String status) {
    switch (status) {
      case 'in_progress':
        return statusInProgress;
      case 'done':
        return statusDone;
      case 'todo':
      default:
        return statusTodo;
    }
  }

  // ── Background Gradient ────────────────────────────────
  static const Color gradientTop = Color(0xFFFAFCFC);
  static const Color gradientBottom = Color(0xFFE2EAEB);

  // ── Space Card Accent Colors ───────────────────────────
  static const List<Color> spaceAccents = [
    Color(0xFF2F6264),
    Color(0xFFF5A623),
    Color(0xFF4CAF50),
    Color(0xFF5C6BC0),
    Color(0xFFEF5350),
  ];

  // ── Convenience ──────────────────────────────────────────
  static const Color cardShadow = Color(0x1A000000); // 10% black
  static const Color divider = Color(0xFFE0E0E0);

  // ── Dark Mode Colors ─────────────────────────────────────
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCardSurface = Color(0xFF2C2C2E);
  static const Color darkScaffold = Color(0xFF000000);
  static const Color darkTextPrimary = Color(0xFFE5E5E7);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkDivider = Color(0xFF38383A);
  static const Color darkPrimaryContainer = Color(0xFF1A3A3C);
  static const Color darkPrimary = Color(0xFF77B5B3);
  static const Color darkGradientTop = Color(0xFF0A0A0A);
  static const Color darkGradientBottom = Color(0xFF1C1C1E);
  static const Color darkCardShadow = Color(0x40000000); // 25% black
}
