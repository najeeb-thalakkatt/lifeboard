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

  // ── Input ────────────────────────────────────────────────
  static const Color inputFill = Color(0xFFF5F7F8);

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

/// Theme extension that provides mode-aware colors.
///
/// Access via `Theme.of(context).extension<AppColorsExtension>()!`.
/// Eliminates `isDark ? AppColors.dark* : AppColors.*` ternaries.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.divider,
    required this.cardShadow,
    required this.gradientTop,
    required this.gradientBottom,
    required this.scaffold,
    required this.cardSurface,
    required this.subtleShadow,
  });

  final Color divider;
  final Color cardShadow;
  final Color gradientTop;
  final Color gradientBottom;
  final Color scaffold;
  final Color cardSurface;
  final Color subtleShadow;

  /// Light mode values.
  static final light = AppColorsExtension(
    divider: AppColors.divider,
    cardShadow: AppColors.cardShadow,
    gradientTop: AppColors.gradientTop,
    gradientBottom: AppColors.gradientBottom,
    scaffold: AppColors.background,
    cardSurface: AppColors.surface,
    subtleShadow: Colors.black.withValues(alpha: 0.08),
  );

  /// Dark mode values.
  static final dark = AppColorsExtension(
    divider: AppColors.darkDivider,
    cardShadow: AppColors.darkCardShadow,
    gradientTop: AppColors.darkGradientTop,
    gradientBottom: AppColors.darkGradientBottom,
    scaffold: AppColors.darkScaffold,
    cardSurface: AppColors.darkCardSurface,
    subtleShadow: Colors.white.withValues(alpha: 0.06),
  );

  @override
  AppColorsExtension copyWith({
    Color? divider,
    Color? cardShadow,
    Color? gradientTop,
    Color? gradientBottom,
    Color? scaffold,
    Color? cardSurface,
    Color? subtleShadow,
  }) {
    return AppColorsExtension(
      divider: divider ?? this.divider,
      cardShadow: cardShadow ?? this.cardShadow,
      gradientTop: gradientTop ?? this.gradientTop,
      gradientBottom: gradientBottom ?? this.gradientBottom,
      scaffold: scaffold ?? this.scaffold,
      cardSurface: cardSurface ?? this.cardSurface,
      subtleShadow: subtleShadow ?? this.subtleShadow,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      divider: Color.lerp(divider, other.divider, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      gradientTop: Color.lerp(gradientTop, other.gradientTop, t)!,
      gradientBottom: Color.lerp(gradientBottom, other.gradientBottom, t)!,
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      subtleShadow: Color.lerp(subtleShadow, other.subtleShadow, t)!,
    );
  }
}
