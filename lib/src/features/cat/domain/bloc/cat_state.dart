import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';

class CatState {
  const CatState({
    required this.isLoading,
    this.cat,
    this.error,
    this.updatedAt,
  });

  const CatState.initial() : this(isLoading: false);

  const CatState.loading({CatEntity? previousCat, DateTime? previousUpdatedAt})
    : this(isLoading: true, cat: previousCat, updatedAt: previousUpdatedAt);

  const CatState.success(CatEntity cat, DateTime updatedAt)
    : this(isLoading: false, cat: cat, updatedAt: updatedAt);

  const CatState.failure(
    Object error, {
    CatEntity? previousCat,
    DateTime? previousUpdatedAt,
  }) : this(
         isLoading: false,
         error: error,
         cat: previousCat,
         updatedAt: previousUpdatedAt,
       );

  final bool isLoading;
  final CatEntity? cat;
  final Object? error;
  final DateTime? updatedAt;

  bool get hasError => error != null;
}
