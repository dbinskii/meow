import 'package:flutter/material.dart';

class SplashCrossFadeLayer extends StatelessWidget {
  const SplashCrossFadeLayer({
    super.key,
    required this.child,
    required this.isVisible,
    required this.duration,
  });

  final Widget child;
  final bool isVisible;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: duration,
      curve: Curves.easeInOut,
      opacity: isVisible ? 1 : 0,
      child: child,
    );
  }
}
