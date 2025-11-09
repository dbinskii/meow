import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:meow/src/core/widgets/secondary_app_bar.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';
import 'package:meow/src/features/cat/presentation/mixins/cat_view_mixin.dart';
import 'package:meow/src/features/cat/presentation/widgets/cat_card.dart';
import 'package:meow/src/features/cat/presentation/widgets/cat_header.dart';

class CatHistoryViewDetails extends StatefulWidget {
  const CatHistoryViewDetails({super.key, required this.cat});

  final CatEntity cat;

  @override
  State<CatHistoryViewDetails> createState() => _CatHistoryViewDetailsState();
}

class _CatHistoryViewDetailsState extends State<CatHistoryViewDetails>
    with CatViewMixin<CatHistoryViewDetails> {
  static const double _initialZoom = 1;
  static const double _zoomStep = 0.2;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 2.5;

  double _zoom = _initialZoom;

  bool get _canZoomIn => _zoom < _maxZoom;
  bool get _canZoomOut => _zoom > _minZoom;

  double _clampZoom(double value) => value.clamp(_minZoom, _maxZoom);

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
    final imageUrl = widget.cat.cachedPath ?? widget.cat.url;

    return Scaffold(
      appBar: SecondaryAppBar(label: localizations.commonBackLabel),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CatHeader(
                title: localizations.historyTitle,
                subtitle: localizations.historyUpdatedLabel,
                timestamp: formatUpdatedAt(widget.cat.createdAt),
              ),
              const SizedBox(height: 24),
              CatCard(
                imageUrl: imageUrl,
                zoom: _zoom,
                aspectRatio: 1,
                onZoomIn: _canZoomIn ? _handleZoomIn : null,
                onZoomOut: _canZoomOut ? _handleZoomOut : null,
                onOpenInBrowser: () => openCatInBrowser(widget.cat.url),
                showViewHistoryButton: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
