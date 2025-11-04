import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow/src/core/constants/cat_api_constants.dart';
import 'package:meow/src/features/cat/data/api/cat_api.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';

void main() {
  group('CatApiImpl', () {
    late CatApiImpl api;

    setUp(() {
      api = CatApiImpl();
    });

    tearDown(() {
      api.dispose();
    });

    test('getRandomCat returns CatEntity with valid data from API', () async {
      // Act
      final result = await api.getRandomCat();

      // Debug log
      debugPrint('=== RESULT ===');
      debugPrint('ID: ${result.id}');
      debugPrint('URL: ${result.url}');
      debugPrint('CreatedAt: ${result.createdAt}');
      debugPrint('Full result: $result');
      debugPrint('==============');

      // Assert
      expect(result, isA<CatEntity>());
      expect(result.id, isNotEmpty);
      expect(result.url, isNotEmpty);
      expect(result.url, contains(CatApiConstants.baseUrl));
      expect(result.url, contains(CatApiConstants.catEndpoint));
      expect(result.createdAt, isA<DateTime>());
      expect(result.cachedPath, isNull);
    });

    test('getRandomCat returns entity with correct URL format', () async {
      // Act
      final result = await api.getRandomCat();

      // Assert
      expect(result.url, startsWith('https://'));
      expect(result.url, contains('.com'));
      expect(result.url, contains('position=center'));
    });

    test('getRandomCat returns entity with valid createdAt date', () async {
      // Act
      final result = await api.getRandomCat();

      // Assert
      expect(result.createdAt, isA<DateTime>());
      expect(
        result.createdAt.isBefore(DateTime.now().add(const Duration(days: 1))),
        isTrue,
      );
    });

    test('getRandomCat returns entity with non-empty id', () async {
      // Act
      final result = await api.getRandomCat();

      // Assert
      expect(result.id, isNotEmpty);
      expect(result.id.length, greaterThan(0));
    });

    test('getRandomCat constructs correct URI', () async {
      // Act
      final result = await api.getRandomCat();

      // Assert
      expect(
        result.url,
        contains('${CatApiConstants.baseUrl}${CatApiConstants.catEndpoint}'),
      );
      expect(result.url, contains('position=center'));
    });
  });
}
