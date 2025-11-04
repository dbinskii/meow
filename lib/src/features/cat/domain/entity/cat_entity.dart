class CatEntity {
  final String id;
  final String url;
  final DateTime createdAt;
  final String? cachedPath;

  const CatEntity({
    required this.id,
    required this.url,
    required this.createdAt,
    this.cachedPath,
  });
}
