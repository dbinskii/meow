import 'package:flutter/material.dart';
import 'package:meow/src/core/theme/app_colors.dart';
import 'package:meow/src/core/theme/app_typography.dart';

class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SecondaryAppBar({super.key, this.label, this.onBack, this.action});

  final String? label;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.appBar,
      automaticallyImplyLeading: false,
      elevation: 0,
      leadingWidth: 110,
      titleSpacing: 0,
      leading: TextButton.icon(
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.primaryButtonContent,
        ),
        label: Text(
          label ?? MaterialLocalizations.of(context).backButtonTooltip,
          style: AppTypography.textTheme.bodyMedium!.copyWith(
            color: AppColors.primaryButtonContent,
          ),
        ),
      ),
      actions: action == null
          ? null
          : [Padding(padding: const EdgeInsets.only(right: 16), child: action)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
