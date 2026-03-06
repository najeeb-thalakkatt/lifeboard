import 'package:flutter/material.dart';

/// A widget that animates its child with a slide-up + fade-in effect.
///
/// Use in list views to create a staggered entrance animation.
/// Each item should receive an increasing [index] to offset its delay.
class StaggeredListItem extends StatefulWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 350),
    this.verticalOffset = 20.0,
  });

  /// The index of this item in the list (used to calculate stagger delay).
  final int index;

  /// The child widget to animate.
  final Widget child;

  /// Delay between each item's animation start.
  final Duration baseDelay;

  /// Duration of the animation.
  final Duration duration;

  /// How far the item slides up from (in logical pixels).
  final double verticalOffset;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: Offset(0, widget.verticalOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Stagger the start based on index
    final delay = widget.baseDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect Reduce Motion accessibility setting
    if (MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
