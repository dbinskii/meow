import 'package:meow/src/features/cat/data/storage/cat_local_data_source.dart';
import 'package:meow/src/features/cat/domain/api/cat_api.dart';
import 'package:meow/src/features/cat/domain/config/cat_refresh_config.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';
import 'package:meow/src/features/cat/domain/repositories/cat_repository.dart';

class CatRepositoryImpl implements CatRepository {
  CatRepositoryImpl({required CatApi api, CatLocalDataSource? localDataSource})
    : _api = api,
      _localDataSource = localDataSource ?? CatLocalDataSource();

  final CatApi _api;
  final CatLocalDataSource _localDataSource;

  @override
  Future<CatEntity> getRandomCat({bool forceRefresh = false}) async {
    final cached = await _localDataSource.getCachedCat();
    final now = DateTime.now();

    if (!forceRefresh && cached != null) {
      final isFresh =
          now.difference(cached.createdAt) < CatRefreshConfig.interval;
      if (isFresh) {
        return cached;
      }
    }

    final remoteCat = await _api.getRandomCat();
    final fetchedAt = DateTime.now();
    try {
      return await _localDataSource.saveCat(
        remoteCat.copyWith(createdAt: fetchedAt),
      );
    } on Exception {
      return remoteCat.copyWith(createdAt: fetchedAt);
    }
  }

  @override
  Future<List<CatEntity>> getHistory() {
    return _localDataSource.getHistory();
  }

  @override
  Future<CatEntity?> getLastCachedCat() {
    return _localDataSource.getCachedCat();
  }
}
