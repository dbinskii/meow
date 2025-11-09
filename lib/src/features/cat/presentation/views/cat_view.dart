import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:meow/src/core/navigation/app_router.dart';
import 'package:meow/src/core/widgets/app_button.dart';
import 'package:meow/src/core/widgets/primary_app_bar.dart';
import 'package:meow/src/features/cat/data/api/cat_api.dart';
import 'package:meow/src/features/cat/data/repositories/cat_repository.dart';
import 'package:meow/src/features/cat/domain/bloc/cat_bloc.dart';
import 'package:meow/src/features/cat/domain/bloc/cat_state.dart';
import 'package:meow/src/features/cat/presentation/mixins/cat_view_mixin.dart';
import 'package:meow/src/features/cat/presentation/widgets/cat_card.dart';
import 'package:meow/src/features/cat/presentation/widgets/cat_header.dart';

class CatView extends StatefulWidget {
  const CatView({super.key});

  @override
  State<CatView> createState() => _CatViewState();
}

class _CatViewState extends State<CatView> with CatViewMixin<CatView> {
  late final CatBloc _bloc;
  static const double _initialZoom = 1;
  static const double _zoomStep = 0.2;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 2.5;

  double _zoom = _initialZoom;

  @override
  void initState() {
    super.initState();
    _bloc = CatBloc(repository: CatRepositoryImpl(api: CatApiImpl()));
    _bloc.loadCat();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  bool get _canZoomIn => _zoom < _maxZoom;
  bool get _canZoomOut => _zoom > _minZoom;

  double _clampZoom(double value) => value.clamp(_minZoom, _maxZoom);

  void _handleRefresh() {
    setState(() {
      _zoom = _initialZoom;
    });
    _bloc.loadCat(forceRefresh: true);
  }

  void _handleZoomIn() {
    if (!_canZoomIn) {
      return;
    }
    setState(() {
      _zoom = _clampZoom(_zoom + _zoomStep);
    });
  }

  void _handleZoomOut() {
    if (!_canZoomOut) {
      return;
    }
    setState(() {
      _zoom = _clampZoom(_zoom - _zoomStep);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: PrimaryAppBar(
        action: IconButton(
          icon: const Icon(Icons.cached),
          onPressed: _handleRefresh,
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<CatState>(
          stream: _bloc.stream,
          initialData: _bloc.state,
          builder: (context, snapshot) {
            final state = snapshot.data ?? _bloc.state;
            final isInitialLoading = state.isLoading && state.cat == null;

            if (state.hasError && state.cat == null) {
              return _CatError(onRetry: _handleRefresh);
            }

            final cat = state.cat;
            if (cat == null && !isInitialLoading) {
              return const SizedBox.shrink();
            }

            final isRefreshing = state.isLoading && cat != null;
            final subtitle = isInitialLoading
                ? localizations.todayCatSubtitle
                : localizations.todayCatUpdatedLabel;
            final timestamp = isInitialLoading
                ? '--:--'
                : formatUpdatedAt(state.updatedAt ?? DateTime.now());

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatHeader(
                    title: localizations.todayCatTitle,
                    subtitle: subtitle,
                    timestamp: timestamp,
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      if (cat != null)
                        CatCard(
                          imageUrl: cat.cachedPath ?? cat.url,
                          zoom: _zoom,
                          onZoomIn: _canZoomIn ? _handleZoomIn : null,
                          onZoomOut: _canZoomOut ? _handleZoomOut : null,
                          onOpenInBrowser: () => openCatInBrowser(cat.url),
                          onViewHistory: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRouter.catHistory);
                          },
                          showLoader: isRefreshing,
                        )
                      else
                        const CatCardPlaceholder(),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CatError extends StatelessWidget {
  const _CatError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.todayCatErrorTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.todayCatErrorMessage,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: localizations.todayCatRetryButton,
              onPressed: onRetry,
              trailingIcon: Icons.refresh,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
