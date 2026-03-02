import 'package:flutter/material.dart';

/// Reusable app bar matching Lifeboard design (flat, themed via AppTheme).
class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SharedAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  final String title;

  /// Optional custom title widget. When provided, overrides [title] text.
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? Text(title),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
    );
  }
}
