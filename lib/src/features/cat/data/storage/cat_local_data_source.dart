import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatLocalDataSource {
  CatLocalDataSource({SharedPreferences? preferences, HttpClient? httpClient})
    : _preferences = preferences,
      _httpClient = httpClient ?? HttpClient();

  static const _cacheKey = 'cat_cache';
  static const _historyKey = 'cat_history';
  static const _maxHistoryLength = 30;

  SharedPreferences? _preferences;
  final HttpClient _httpClient;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<CatEntity?> getCachedCat() async {
    final prefs = await _prefs;
    final cachedRaw = prefs.getString(_cacheKey);
    if (cachedRaw == null) {
      return null;
    }

    try {
      final json = jsonDecode(cachedRaw) as Map<String, dynamic>;
      final cachedPath = json['cachedPath'] as String?;
      if (cachedPath == null) {
        await prefs.remove(_cacheKey);
        return null;
      }

      final cachedFile = File(cachedPath);
      if (!cachedFile.existsSync()) {
        await prefs.remove(_cacheKey);
        return null;
      }

      final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
      if (createdAt == null) {
        await prefs.remove(_cacheKey);
        return null;
      }

      return CatEntity(
        id: json['id'] as String? ?? '',
        url: json['url'] as String? ?? '',
        createdAt: createdAt,
        cachedPath: cachedPath,
      );
    } on FormatException {
      await prefs.remove(_cacheKey);
      return null;
    }
  }

  Future<CatEntity> saveCat(CatEntity cat) async {
    final prefs = await _prefs;
    final storedPath = await _downloadAndStore(cat.url);

    final cachedCat = cat.copyWith(cachedPath: storedPath);

    final payload = jsonEncode({
      'id': cachedCat.id,
      'url': cachedCat.url,
      'createdAt': cachedCat.createdAt.toIso8601String(),
      'cachedPath': cachedCat.cachedPath,
    });

    await prefs.setString(_cacheKey, payload);

    await _appendToHistory(prefs, cachedCat);

    return cachedCat;
  }

  Future<List<CatEntity>> getHistory() async {
    final prefs = await _prefs;
    return _readHistory(prefs);
  }

  Future<String> _downloadAndStore(String url) async {
    final uri = Uri.parse(url);
    final request = await _httpClient.getUrl(uri);
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Failed to download image: ${response.statusCode}',
        uri: uri,
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = _resolveFileName(uri);
    final file = File('${directory.path}/$fileName');

    final bytesBuilder = BytesBuilder();
    await for (final chunk in response) {
      bytesBuilder.add(chunk);
    }

    await file.writeAsBytes(bytesBuilder.takeBytes(), flush: true);

    return file.path;
  }

  String? _extractCachedPath(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json['cachedPath'] as String?;
    } on FormatException {
      return null;
    }
  }

  void _deleteFile(String path) {
    final file = File(path);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } on IOException {
        // Ignore deletion errors.
      }
    }
  }

  String _resolveFileName(Uri uri) {
    final segments = uri.pathSegments;
    final lastSegment = segments.isNotEmpty ? segments.last : '';
    final extension = _resolveExtension(lastSegment);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'cat_$timestamp.$extension';
  }

  String _resolveExtension(String segment) {
    final parts = segment.split('.');
    if (parts.length < 2) {
      return 'jpg';
    }
    final ext = parts.last.toLowerCase();
    if (ext.isEmpty || ext.length > 5) {
      return 'jpg';
    }
    return ext;
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    final history = await _readHistory(prefs, sanitize: false);
    final cachedPath = _extractCachedPath(prefs.getString(_cacheKey));

    final processed = <String>{};

    if (cachedPath != null) {
      processed.add(cachedPath);
      _deleteFile(cachedPath);
    }

    for (final cat in history) {
      final path = cat.cachedPath;
      if (path != null && processed.add(path)) {
        _deleteFile(path);
      }
    }

    await prefs.remove(_cacheKey);
    await prefs.remove(_historyKey);
  }

  void dispose() {
    _httpClient.close(force: true);
  }

  Future<void> _appendToHistory(SharedPreferences prefs, CatEntity cat) async {
    final history = await _readHistory(prefs);
    final filtered =
        history
            .where((entry) => entry.cachedPath != cat.cachedPath)
            .toList(growable: true)
          ..insert(0, cat);

    final removedPaths = <String>{};

    while (filtered.length > _maxHistoryLength) {
      final removed = filtered.removeLast();
      final path = removed.cachedPath;
      if (path != null) {
        removedPaths.add(path);
      }
    }

    await _writeHistory(prefs, filtered);

    for (final path in removedPaths) {
      if (path != cat.cachedPath) {
        _deleteFile(path);
      }
    }
  }

  Future<List<CatEntity>> _readHistory(
    SharedPreferences prefs, {
    bool sanitize = true,
  }) async {
    final historyRaw = prefs.getString(_historyKey);
    if (historyRaw == null) {
      return [];
    }

    final decoded = jsonDecode(historyRaw);
    if (decoded is! List<dynamic>) {
      if (sanitize) {
        await prefs.remove(_historyKey);
      }
      return [];
    }

    final sanitized = <CatEntity>[];
    var hasChanges = false;

    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) {
        hasChanges = true;
        continue;
      }

      final cachedPath = entry['cachedPath'] as String?;
      final createdAtRaw = entry['createdAt'] as String?;
      if (cachedPath == null || createdAtRaw == null) {
        hasChanges = true;
        continue;
      }

      final file = File(cachedPath);
      if (!file.existsSync()) {
        hasChanges = true;
        continue;
      }

      final createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt == null) {
        hasChanges = true;
        continue;
      }

      sanitized.add(
        CatEntity(
          id: entry['id'] as String? ?? '',
          url: entry['url'] as String? ?? '',
          createdAt: createdAt,
          cachedPath: cachedPath,
        ),
      );
    }

    if (sanitize && hasChanges) {
      await _writeHistory(prefs, sanitized);
    }

    return sanitized;
  }

  Future<void> _writeHistory(
    SharedPreferences prefs,
    List<CatEntity> history,
  ) async {
    if (history.isEmpty) {
      await prefs.remove(_historyKey);
      return;
    }

    final payload = history
        .map(
          (cat) => {
            'id': cat.id,
            'url': cat.url,
            'createdAt': cat.createdAt.toIso8601String(),
            'cachedPath': cat.cachedPath,
          },
        )
        .toList();

    await prefs.setString(_historyKey, jsonEncode(payload));
  }
}
