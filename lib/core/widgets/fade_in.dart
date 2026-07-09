import 'package:flutter/material.dart';

/// FadeInUp
/// --------
/// Wrap any widget to make it fade in while sliding up slightly when it first
/// appears. Pass an increasing [delay] to neighbouring items to get a smooth
/// "staggered" reveal (e.g. cards cascading in one after another).
///
/// Implemented with AnimatedOpacity/AnimatedSlide toggled after [delay], so
/// there's no AnimationController to manage and it's safe to scatter freely.
class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
  });

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      // Next frame so the animation has a "from" state to animate out of.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _shown = true);
      });
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _shown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: widget.duration,
      curve: Curves.easeOut,
      opacity: _shown ? 1 : 0,
      child: AnimatedSlide(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        offset: _shown ? Offset.zero : const Offset(0, 0.08),
        child: widget.child,
      ),
    );
  }
}
