import 'package:flutter/material.dart';
import 'package:meow/src/core/constants/app_assets.dart';
import 'package:meow/src/core/theme/app_colors.dart';

class SplashOrangeBackground extends StatelessWidget {
  const SplashOrangeBackground({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        const overflowWidthFactor = 1.6;
        const topAspectRatio = 1572 / 1853;
        const bottomAspectRatio = 1572 / 2130;
        final topWidth = size.width * overflowWidthFactor;
        final bottomWidth = size.width * overflowWidthFactor;
        final bottomHeight = bottomWidth / bottomAspectRatio;

        return ColoredBox(
          color: AppColors.backgroundQuinary,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                AppAssets.backgrounds.orangeComponent,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(
                    -size.width * 0.57 - size.width * 0.5 * progress,
                    0,
                  ),
                  child: Transform.rotate(
                    angle: -0.18 * progress,
                    child: AspectRatio(
                      aspectRatio: topAspectRatio,
                      child: OverflowBox(
                        maxWidth: topWidth,
                        minWidth: topWidth,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: topWidth,
                          child: Image.asset(
                            AppAssets.backgrounds.topBlueComponent,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Transform.translate(
                  offset: Offset(
                    size.width * 0.52 + size.width * 0.4 * progress,
                    bottomHeight * 0.01 * (1 - progress),
                  ),
                  child: Transform.rotate(
                    angle: 0.15 * progress,
                    child: AspectRatio(
                      aspectRatio: bottomAspectRatio,
                      child: OverflowBox(
                        maxWidth: bottomWidth,
                        minWidth: bottomWidth,
                        alignment: Alignment.bottomRight,
                        child: SizedBox(
                          width: bottomWidth,
                          child: Image.asset(
                            AppAssets.backgrounds.bottomBlueComponent,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
