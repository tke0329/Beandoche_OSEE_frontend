import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/catalog_garment.dart';

class GarmentFailure implements Exception {
  const GarmentFailure(this.message, {this.status});
  final String message;
  final int? status;
}

class GarmentApi {
  GarmentApi({
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

  Uri get _base {
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        !_safeImageUri(base)) {
      throw const GarmentFailure('서버 주소 설정을 확인해 주세요.');
    }
    return base;
  }

  Future<GarmentPage> fetch(
    String accessToken, {
    String? categoryCode,
    int page = 0,
    int size = 20,
  }) async {
    final base = _base;
    if (accessToken.isEmpty) {
      throw const GarmentFailure('로그인 후 상품을 확인해 주세요.', status: 401);
    }
    try {
      final response = await _client
          .get(
            base
                .resolve('/api/garments')
                .replace(
                  queryParameters: {
                    'categoryCode': ?categoryCode,
                    'page': '$page',
                    'size': '$size',
                    'sort': 'LATEST',
                  },
                ),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw GarmentFailure(switch (response.statusCode) {
          401 => '로그인 상태를 확인하지 못했습니다. 다시 시도해 주세요.',
          403 => '상품을 조회할 권한이 없습니다.',
          404 => '선택한 카테고리를 찾을 수 없습니다. 다른 카테고리를 선택해 주세요.',
          _ => '상품을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
        }, status: response.statusCode);
      }
      final result = GarmentPage.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
      if (result.page != page || result.size != size) {
        throw const FormatException('Unexpected garment page');
      }
      return result;
    } on GarmentFailure {
      rethrow;
    } on TimeoutException {
      throw const GarmentFailure('응답이 지연되고 있습니다. 다시 시도해 주세요.');
    } on http.ClientException {
      throw const GarmentFailure('서버에 연결하지 못했습니다. 연결 상태를 확인해 주세요.');
    } on FormatException {
      throw const GarmentFailure('상품 정보를 확인하지 못했습니다. 다시 시도해 주세요.');
    }
  }

  String? imageUrl(String value) {
    try {
      if (value.trim().isEmpty) return null;
      final uri = _base.resolve(value);
      return _safeImageUri(uri) ? uri.toString() : null;
    } on GarmentFailure {
      return null;
    } on FormatException {
      return null;
    }
  }

  static bool _safeImageUri(Uri uri) =>
      uri.hasAuthority &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      (uri.scheme == 'https' ||
          (uri.scheme == 'http' &&
              ['localhost', '127.0.0.1', '::1'].contains(uri.host)));

  void close() => _client.close();
}
