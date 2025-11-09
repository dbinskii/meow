import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:meow/src/core/theme/app_colors.dart';
import 'package:meow/src/core/widgets/app_loader.dart';
import 'package:meow/src/core/widgets/circle_icon_button.dart';
import 'package:meow/src/features/cat/presentation/widgets/cat_actions.dart';

class CatCard extends StatelessWidget {
  const CatCard({
    super.key,
    required this.imageUrl,
    required this.onZoomIn,
    required this.onZoomOut,
    this.zoom = 1,
    this.aspectRatio = 6 / 9,
    this.onOpenInBrowser,
    this.onViewHistory,
    this.showViewHistoryButton = true,
    this.showLoader = false,
  });

  final String imageUrl;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final double zoom;
  final double aspectRatio;
  final VoidCallback? onOpenInBrowser;
  final VoidCallback? onViewHistory;
  final bool showViewHistoryButton;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isNetworkImage = imageUrl.startsWith('http');

    const cardRadius = 22.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedScale(
                          scale: zoom,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: _CatImage(
                            imageUrl: imageUrl,
                            isNetworkImage: isNetworkImage,
                          ),
                        ),
                      ),
                      if (showLoader)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                              ),
                              child: const Center(child: AppLoader()),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CircleIconButton(
                                icon: Icons.remove,
                                onPressed: onZoomOut,
                              ),
                              const SizedBox(height: 2),
                              CircleIconButton(
                                icon: Icons.add,
                                onPressed: onZoomIn,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CatActions(
                openInBrowserLabel: localizations.todayCatOpenInBrowser,
                viewHistoryLabel: showViewHistoryButton
                    ? localizations.todayCatViewHistory
                    : null,
                onOpenInBrowser: onOpenInBrowser,
                onViewHistory: showViewHistoryButton ? onViewHistory : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatImage extends StatelessWidget {
  const _CatImage({required this.imageUrl, required this.isNetworkImage});

  final String imageUrl;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    if (isNetworkImage || kIsWeb) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const Center(child: AppLoader()),
        errorBuilder: _errorBuilder,
      );
    }

    return Image.file(
      File(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: _errorBuilder,
    );
  }

  static Widget _errorBuilder(BuildContext context, Object _, StackTrace? __) {
    return const ColoredBox(
      color: AppColors.backgroundTertiary,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.textTertiary,
          size: 48,
        ),
      ),
    );
  }
}

class CatCardPlaceholder extends StatelessWidget {
  const CatCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    const cardRadius = 22.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: 6 / 9,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: Stack(
                    children: [
                      const ColoredBox(
                        color: AppColors.backgroundTertiary,
                        child: Center(child: AppLoader()),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CircleIconButton(
                                icon: Icons.remove,
                                onPressed: () {},
                              ),
                              const SizedBox(height: 2),
                              CircleIconButton(
                                icon: Icons.add,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CatActions(
                onOpenInBrowser: () {},
                onViewHistory: () {},
                openInBrowserLabel: localizations.todayCatOpenInBrowser,
                viewHistoryLabel: localizations.todayCatViewHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
