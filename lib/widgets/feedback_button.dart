import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/theme/app_colors.dart';

/// Small floating bug icon that opens the Sentry feedback widget.
///
/// Resting opacity 0.55, animates to 1.0 on hover/press.
class FeedbackButton extends StatefulWidget {
  const FeedbackButton({super.key});

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => _hovered || _pressed;

  Future<void> _openFeedback() async {
    final screenshot = await SentryFlutter.captureScreenshot();
    if (!mounted) return;
    SentryFeedbackWidget.show(context, screenshot: screenshot);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppConstants.feedbackTooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            _openFeedback();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedOpacity(
            opacity: _active ? 1.0 : 0.55,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bug_report_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
