import 'package:flutter/material.dart';
import 'package:meow/src/core/theme/app_colors.dart';

class CatHeader extends StatelessWidget {
  const CatHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.timestamp,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? timestamp;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ts = timestamp;
    final trailingWidget = trailing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                title,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textPrimary,
                ),
              ),
              if (trailingWidget != null)
                Positioned(top: -12, left: 100, child: trailingWidget),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle, style: textTheme.bodyMedium),
            if (ts != null) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 5,
                height: 5,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.dotSpecial,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(ts, style: textTheme.bodyMedium),
            ],
          ],
        ),
      ],
    );
  }
}
