import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:meow/src/core/navigation/app_router.dart';
import 'package:meow/src/core/theme/app_colors.dart';
import 'package:meow/src/core/widgets/app_loader.dart';
import 'package:meow/src/core/widgets/secondary_app_bar.dart';
import 'package:meow/src/features/cat/data/api/cat_api.dart';
import 'package:meow/src/features/cat/data/repositories/cat_repository.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';
import 'package:meow/src/features/cat/domain/repositories/cat_repository.dart';
import 'package:meow/src/features/cat/presentation/mixins/cat_view_mixin.dart';
import 'package:meow/src/features/cat/presentation/widgets/cat_header.dart';

class CatHistoryView extends StatefulWidget {
  const CatHistoryView({super.key});

  @override
  State<CatHistoryView> createState() => _CatHistoryViewState();
}

class _CatHistoryViewState extends State<CatHistoryView>
    with CatViewMixin<CatHistoryView> {
  late final CatRepository _repository;
  late Future<List<CatEntity>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _repository = CatRepositoryImpl(api: CatApiImpl());
    _historyFuture = _repository.getHistory();
  }

  void _reloadHistory() {
    setState(() {
      _historyFuture = _repository.getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: SecondaryAppBar(label: localizations.commonBackLabel),
      body: SafeArea(
        child: FutureBuilder<List<CatEntity>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoader());
            }

            if (snapshot.hasError) {
              return Center(child: Text(localizations.todayCatErrorMessage));
            }

            final historyCats = snapshot.data ?? const <CatEntity>[];
            final count = historyCats.length;
            final displayItems = historyCats;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatHeader(
                    title: localizations.historyTitle,
                    subtitle: '',
                    trailing: count > 0 ? _HistoryCounter(count: count) : null,
                  ),
                  Expanded(
                    child: GridView.builder(
                      itemCount: displayItems.length,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (context, index) {
                        final cat = displayItems[index];
                        return _HistoryTile(
                          cat: cat,
                          onTap: () async {
                            await Navigator.of(context).pushNamed(
                              AppRouter.catHistoryDetails,
                              arguments: CatHistoryDetailsArgs(cat: cat),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            _reloadHistory();
                          },
                        );
                      },
                    ),
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.cat, required this.onTap});

  final CatEntity cat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    final imagePath = cat.cachedPath;

    Widget image;
    if (!kIsWeb && imagePath != null && imagePath.isNotEmpty) {
      image = Image.file(File(imagePath), fit: BoxFit.cover);
    } else {
      image = Image.network(cat.url, fit: BoxFit.cover);
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(borderRadius: borderRadius, child: image),
    );
  }
}

class _HistoryCounter extends StatelessWidget {
  const _HistoryCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '$count',
          style: textTheme.bodyMedium!.copyWith(
            color: AppColors.secondaryButtonContent,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
