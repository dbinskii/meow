import 'package:flutter/material.dart';
import 'package:meow/src/core/theme/app_colors.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.secondaryButton,
        disabledBackgroundColor: AppColors.secondaryButton.withValues(
          alpha: 0.4,
        ),
        shape: const CircleBorder(),
      ),
    );
  }
}
