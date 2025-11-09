import 'package:flutter/material.dart';
import 'package:meow/src/core/theme/app_colors.dart';
import 'package:meow/src/core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.variant,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();
    final contentColor = _resolveContentColor();

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shadowColor: colors.shadow,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.textTheme.bodyMedium!.copyWith(
                color: contentColor,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: contentColor, size: 22),
            ],
          ],
        ),
      ),
    );
  }

  Color _resolveContentColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primaryButtonContent;
      case AppButtonVariant.secondary:
        return AppColors.secondaryButtonContent;
    }
  }

  _ButtonColors _resolveColors() {
    switch (variant) {
      case AppButtonVariant.primary:
        return const _ButtonColors(
          background: AppColors.primaryButton,
          foreground: AppColors.primaryButtonContent,
          shadow: Colors.transparent,
        );
      case AppButtonVariant.secondary:
        return const _ButtonColors(
          background: AppColors.secondaryButton,
          foreground: AppColors.secondaryButtonContent,
          shadow: Colors.transparent,
        );
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.shadow,
  });

  final Color background;
  final Color foreground;
  final Color? shadow;
}
