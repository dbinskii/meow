import 'package:flutter/material.dart';
import 'package:meow/src/core/theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 100, this.strokeWidth = 10});

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        backgroundColor: AppColors.loaderBackground,
        valueColor: const AlwaysStoppedAnimation<Color>(
          AppColors.loaderProgress,
        ),
      ),
    );
  }
}
