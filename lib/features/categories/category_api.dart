import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'catalog_category.dart';

class CategoryFailure implements Exception {
  const CategoryFailure(this.message, {this.status});
  final String message;
  final int? status;
}

class CategoryApi {
  CategoryApi({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'OSEE_API_BASE_URL',
             defaultValue: 'http://localhost:8080',
           );
  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

  Future<List<CatalogCategory>> fetch(String accessToken) async {
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.scheme != 'https' &&
            !(base.scheme == 'http' &&
                ['localhost', '127.0.0.1', '::1'].contains(base.host)))) {
      throw const CategoryFailure('서버 주소 설정을 확인해 주세요.');
    }
    if (accessToken.isEmpty) {
      throw const CategoryFailure('로그인 후 카테고리를 확인해 주세요.', status: 401);
    }
    try {
      final response = await _client
          .get(
            base.resolve('/api/categories'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw CategoryFailure(switch (response.statusCode) {
          401 => '로그인 상태를 확인하지 못했습니다. 다시 시도해 주세요.',
          403 => '카테고리를 조회할 권한이 없습니다.',
          _ => '카테고리를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
        }, status: response.statusCode);
      }
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      if (value is! List<Object?>) {
        throw const FormatException('Invalid category list');
      }
      return List.unmodifiable(value.map(CatalogCategory.fromJson));
    } on CategoryFailure {
      rethrow;
    } on TimeoutException {
      throw const CategoryFailure('응답이 지연되고 있습니다. 다시 시도해 주세요.');
    } on http.ClientException {
      throw const CategoryFailure('서버에 연결하지 못했습니다. 연결 상태를 확인해 주세요.');
    } on FormatException {
      throw const CategoryFailure('카테고리 정보를 확인하지 못했습니다. 다시 시도해 주세요.');
    }
  }

  void close() => _client.close();
}
