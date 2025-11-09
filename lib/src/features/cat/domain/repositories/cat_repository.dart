import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';

abstract class CatRepository {
  Future<CatEntity> getRandomCat({bool forceRefresh = false});
  Future<List<CatEntity>> getHistory();
  Future<CatEntity?> getLastCachedCat();
}
