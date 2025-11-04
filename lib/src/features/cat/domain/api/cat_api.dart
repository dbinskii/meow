import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';

abstract class CatApi {
  Future<CatEntity> getRandomCat();
}
