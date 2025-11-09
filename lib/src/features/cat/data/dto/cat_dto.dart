import 'package:meow/src/core/constants/cat_api_constants.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';

class CatDto {
  final String id;
  final List<String> tags;
  final String createdAt;
  final String url;
  final String mimetype;

  const CatDto({
    required this.id,
    required this.tags,
    required this.createdAt,
    required this.url,
    required this.mimetype,
  });

  factory CatDto.fromJson(Map<String, dynamic> json) => CatDto(
    id: (json['id'] ?? json['_id'] ?? '') as String,
    tags:
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [],
    createdAt: json['created_at'] as String? ?? '',
    url: json['url'] as String? ?? '',
    mimetype: json['mimetype'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tags': tags,
    'created_at': createdAt,
    'url': url,
    'mimetype': mimetype,
  };

  CatEntity toEntity() {
    final parsedCreatedAt = createdAt.isNotEmpty
        ? DateTime.tryParse(createdAt)
        : null;
    final resolvedUrl = url.startsWith('http')
        ? url
        : '${CatApiConstants.baseUrl}$url';

    return CatEntity(
      id: id,
      url: resolvedUrl,
      createdAt: parsedCreatedAt ?? DateTime.now(),
    );
  }
}
