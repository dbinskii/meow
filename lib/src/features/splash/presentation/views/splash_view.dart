import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meow/src/core/constants/app_assets.dart';
import 'package:meow/src/core/navigation/app_router.dart';
import 'package:meow/src/core/theme/app_colors.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const Duration _backgroundSwitchDelay = Duration(milliseconds: 1200);
  static const Duration _navigationDelay = Duration(milliseconds: 2000);
  static const Duration _crossFadeDuration = Duration(milliseconds: 600);

  Timer? _backgroundSwitchTimer;
  Timer? _navigationTimer;

  bool _showImageBackground = true;

  @override
  void initState() {
    super.initState();
    _backgroundSwitchTimer = Timer(
      _backgroundSwitchDelay,
      _handleBackgroundSwitch,
    );
    _navigationTimer = Timer(_navigationDelay, _handleNavigation);
  }

  @override
  void dispose() {
    _backgroundSwitchTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _handleBackgroundSwitch() {
    if (!mounted) {
      return;
    }
    setState(() => _showImageBackground = false);
  }

  void _handleNavigation() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRouter.cat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedCrossFade(
            duration: _crossFadeDuration,
            crossFadeState: _showImageBackground
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const _BlueBackground(),
            secondChild: const _OrangeBackground(),
          ),
        ],
      ),
    );
  }
}

class _BlueBackground extends StatelessWidget {
  const _BlueBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.backgroundSenary),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.backgrounds.topBlueComponent,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              AppAssets.backgrounds.bottomBlueComponent,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrangeBackground extends StatelessWidget {
  const _OrangeBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.backgroundQuinary),
      child: Align(
        child: Image.asset(
          AppAssets.backgrounds.orangeComponent,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
}
