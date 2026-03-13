// Pattern: Using theme colors and text styles
// Source: lib/widgets/task_card.dart, lib/theme/
// Usage: All UI code should use theme instead of hardcoded values

import 'package:flutter/material.dart';
import 'package:lifeboard/theme/app_colors.dart';
import 'package:lifeboard/theme/app_text_styles.dart';

// ── Accessing colors ───────────────────────────────────────

// Material color scheme (adapts to light/dark)
final colors = Theme.of(context).colorScheme;
colors.surface;          // Card backgrounds
colors.primary;          // Primary teal
colors.onSurface;        // Text on surface

// Custom AppColorsExtension (mode-aware custom colors)
final ext = Theme.of(context).extension<AppColorsExtension>()!;
ext.cardShadow;          // Shadow color
ext.subtleText;          // Secondary text

// Static colors (same in light/dark)
AppColors.primary;       // #2F6264
AppColors.accent;        // #F5A623
AppColors.error;         // #D94F4F
AppColors.statusAccent('todo');        // #2F6264
AppColors.statusAccent('in_progress'); // #F5A623
AppColors.statusAccent('done');        // #4CAF50

// ── Accessing text styles ──────────────────────────────────

AppTextStyles.heading1;   // Nunito Bold 28sp
AppTextStyles.heading2;   // Nunito Bold 24sp
AppTextStyles.heading3;   // Nunito Bold 20sp
AppTextStyles.bodyLarge;   // Inter 16sp
AppTextStyles.bodyMedium;  // Inter 14sp
AppTextStyles.bodySmall;   // Inter 12sp
AppTextStyles.button;      // Inter SemiBold 14sp

// ── Card styling conventions ───────────────────────────────

Container(
  decoration: BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(12),  // Always 12-16px
    boxShadow: [BoxShadow(color: ext.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
  ),
  child: Row(
    children: [
      // Left accent bar (status color)
      Container(width: 4, color: AppColors.statusAccent(task.status)),
      // Content
    ],
  ),
);
