import 'package:flutter/material.dart';
import 'package:meow/src/core/widgets/app_button.dart';

class CatActions extends StatelessWidget {
  const CatActions({
    super.key,
    required this.openInBrowserLabel,
    this.onOpenInBrowser,
    this.viewHistoryLabel,
    this.onViewHistory,
  });

  final String openInBrowserLabel;
  final String? viewHistoryLabel;
  final VoidCallback? onOpenInBrowser;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: openInBrowserLabel,
          trailingIcon: Icons.arrow_forward,
          onPressed: onOpenInBrowser,
          variant: AppButtonVariant.secondary,
        ),
        if (viewHistoryLabel != null) ...[
          const SizedBox(height: 16),
          AppButton(
            label: viewHistoryLabel!,
            trailingIcon: Icons.history,
            onPressed: onViewHistory,
            variant: AppButtonVariant.primary,
          ),
        ],
      ],
    );
  }
}
