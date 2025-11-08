import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meow/src/core/navigation/app_router.dart';
import 'package:meow/src/features/splash/presentation/widgets/splash_blue_background.dart';
import 'package:meow/src/features/splash/presentation/widgets/splash_cross_fade_layer.dart';
import 'package:meow/src/features/splash/presentation/widgets/splash_orange_background.dart';
import 'package:meow/src/features/splash/presentation/widgets/splash_quaternary_background.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

enum _SplashPhase { orange, blue, quaternary }

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  static const Duration _backgroundSwitchDelay = Duration(milliseconds: 1200);
  static const Duration _quaternarySwitchDelay = Duration(milliseconds: 2300);
  static const Duration _navigationDelay = Duration(milliseconds: 3600);
  static const Duration _crossFadeDuration = Duration(milliseconds: 600);

  final List<Timer> _timers = [];
  late final AnimationController _shapesController;
  late final Animation<double> _shapesAnimation;
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  _SplashPhase _phase = _SplashPhase.orange;

  @override
  void initState() {
    super.initState();
    _shapesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shapesAnimation = CurvedAnimation(
      parent: _shapesController,
      curve: Curves.easeInOutCubic,
    );
    _scheduleTimer(_backgroundSwitchDelay, _handleBackgroundSwitch);
    _scheduleTimer(_quaternarySwitchDelay, _handleQuaternarySwitch);
    _scheduleTimer(_navigationDelay, _handleNavigation);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.45).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _shapesController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _scheduleTimer(Duration delay, VoidCallback callback) {
    _timers.add(Timer(delay, callback));
  }

  void _handleBackgroundSwitch() {
    if (!mounted) {
      return;
    }
    _shapesController.forward();
    _playSplashHaptics();
    setState(() => _phase = _SplashPhase.blue);
  }

  void _handleQuaternarySwitch() {
    if (!mounted) {
      return;
    }
    _logoController.forward();
    setState(() => _phase = _SplashPhase.quaternary);
  }

  void _handleNavigation() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRouter.cat);
  }

  bool get _isOrangeVisible => _phase == _SplashPhase.orange;
  bool get _isBlueVisible => _phase == _SplashPhase.blue;
  bool get _isQuaternaryVisible => _phase == _SplashPhase.quaternary;

  bool get _supportsHaptics {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => true,
      _ => false,
    };
  }

  void _playSplashHaptics() {
    if (!_supportsHaptics) {
      return;
    }
    HapticFeedback.mediumImpact();
    _scheduleTimer(const Duration(milliseconds: 90), _lightImpact);
    _scheduleTimer(const Duration(milliseconds: 220), _heavyImpact);
    _scheduleTimer(const Duration(milliseconds: 420), _selectionClick);
  }

  void _lightImpact() {
    HapticFeedback.lightImpact();
  }

  void _heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  void _selectionClick() {
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SplashCrossFadeLayer(
            isVisible: _isOrangeVisible,
            duration: _crossFadeDuration,
            child: SplashOrangeBackground(animation: _shapesAnimation),
          ),
          SplashCrossFadeLayer(
            isVisible: _isBlueVisible,
            duration: _crossFadeDuration,
            child: const SplashBlueBackground(),
          ),
          SplashCrossFadeLayer(
            isVisible: _isQuaternaryVisible,
            duration: _crossFadeDuration,
            child: SplashQuaternaryBackground(
              scale: _logoScale,
              opacity: _logoOpacity,
            ),
          ),
        ],
      ),
    );
  }
}
