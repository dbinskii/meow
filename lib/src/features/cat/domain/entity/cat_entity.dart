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

  CatEntity copyWith({
    String? id,
    String? url,
    DateTime? createdAt,
    String? cachedPath,
  }) {
    return CatEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
      cachedPath: cachedPath ?? this.cachedPath,
    );
  }
}
