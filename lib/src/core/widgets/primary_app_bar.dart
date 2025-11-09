import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow/src/core/constants/app_assets.dart';
import 'package:meow/src/core/theme/app_colors.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// {@macro primary_app_bar}
  const PrimaryAppBar({
    super.key, // ignore: unused_element
    this.action,
  });

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final paddedAction = action == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 18, bottom: 12),
            child: action,
          );

    return AppBar(
      backgroundColor: AppColors.appBar,
      iconTheme: const IconThemeData(color: AppColors.icon, size: 28),
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 22, bottom: 12),
        child: Center(
          child: SvgPicture.asset(
            AppAssets.icons.secondaryLogo,
            width: 32,
            height: 32,
          ),
        ),
      ),
      actions: paddedAction == null ? null : [paddedAction],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
