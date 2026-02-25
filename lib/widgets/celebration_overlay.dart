import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

/// Full-screen confetti overlay triggered when a task is marked done.
///
/// Shows a Lottie confetti animation for 2 seconds, fires haptic feedback
/// on mobile, then auto-dismisses.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.onComplete,
  });

  /// Called when the animation finishes.
  final VoidCallback onComplete;

  /// Shows the celebration overlay as a full-screen overlay entry.
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => CelebrationOverlay(
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Haptic feedback on mobile
    HapticFeedback.mediumImpact();

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: SizedBox.expand(
          child: Lottie.asset(
            'assets/animations/confetti.json',
            controller: _controller,
            fit: BoxFit.cover,
            repeat: false,
          ),
        ),
      ),
    );
  }
}
