import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow/src/core/constants/app_assets.dart';
import 'package:meow/src/core/theme/app_colors.dart';

class SplashQuaternaryBackground extends StatelessWidget {
  const SplashQuaternaryBackground({
    super.key,
    required this.scale,
    required this.opacity,
  });

  final Animation<double> scale;
  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.backgroundQuaternary),
        IgnorePointer(
          child: Center(
            child: FadeTransition(
              opacity: opacity,
              child: ScaleTransition(
                scale: scale,
                child: SvgPicture.asset(
                  AppAssets.icons.secondaryLogo,
                  width: 160,
                  height: 160,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
