import 'dart:convert';
import 'dart:io';
import 'package:meow/src/core/constants/cat_api_constants.dart';
import 'package:meow/src/features/cat/data/dto/cat_dto.dart';
import 'package:meow/src/features/cat/domain/api/cat_api.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';

class CatApiImpl implements CatApi {
  final HttpClient _httpClient;

  CatApiImpl({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  @override
  Future<CatEntity> getRandomCat() async {
    final uri = Uri.parse(
      '${CatApiConstants.baseUrl}${CatApiConstants.catEndpoint}?position=center',
    );

    final request = await _httpClient.getUrl(uri);
    request.headers.set('Accept', 'application/json');
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Failed to load cat: ${response.statusCode}',
        uri: uri,
      );
    }

    final responseBody = await response.transform(utf8.decoder).join();
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final dto = CatDto.fromJson(json);

    return dto.toEntity();
  }

  void dispose() {
    _httpClient.close(force: true);
  }
}
