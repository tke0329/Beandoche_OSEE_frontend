import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.newUser,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.sessionExpiresAt,
  });

  final int userId;
  final bool newUser;
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final DateTime sessionExpiresAt;

  factory AuthSession.fromJson(Object? value) {
    if (value case {
      'userId': int userId,
      'newUser': bool newUser,
      'tokenType': 'Bearer',
      'accessToken': String accessToken,
      'accessTokenExpiresAt': String accessExpiry,
      'sessionExpiresAt': String sessionExpiry,
    }) {
      final accessAt = DateTime.tryParse(accessExpiry);
      final sessionAt = DateTime.tryParse(sessionExpiry);
      if (userId > 0 && accessToken.isNotEmpty && accessAt != null &&
          sessionAt != null && accessAt.isAfter(DateTime.now()) &&
          !accessAt.isAfter(sessionAt)) {
        // Refresh tokens are intentionally not retained until secure web storage is implemented.
        return AuthSession(userId: userId, newUser: newUser,
            accessToken: accessToken, accessTokenExpiresAt: accessAt,
            sessionExpiresAt: sessionAt);
      }
    }
    throw const AuthFailure('로그인 응답을 확인하지 못했습니다. 다시 시도해 주세요.');
  }
}

class AuthApi {
  AuthApi({String? baseUrl, http.Client? client, this.timeout = const Duration(seconds: 10)})
    : _baseUrl = baseUrl ?? const String.fromEnvironment('OSEE_API_BASE_URL', defaultValue: 'http://localhost:8080'),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<AuthSession> loginWithGoogle(String idToken) async {
    if (idToken.trim().isEmpty) {
      throw const AuthFailure('Google 인증을 다시 진행해 주세요.');
    }
    final base = Uri.tryParse(_baseUrl);
    if (base == null || !base.hasAuthority || base.userInfo.isNotEmpty ||
        base.hasQuery || base.hasFragment ||
        (base.scheme != 'https' && !(base.scheme == 'http' &&
            ['localhost', '127.0.0.1', '::1'].contains(base.host)))) {
      throw const AuthFailure('로그인 서버 주소 설정을 확인해 주세요.');
    }
    try {
      final response = await _client.post(
        base.resolve('/api/auth/social/google'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      ).timeout(timeout);
      if (response.statusCode != 200) {
        throw AuthFailure(switch (response.statusCode) {
          400 || 401 => 'Google 인증이 만료되었거나 유효하지 않습니다. 다시 로그인해 주세요.',
          403 => '이 계정으로 로그인할 수 없습니다.',
          429 => '요청이 많습니다. 잠시 후 다시 시도해 주세요.',
          _ => '로그인 서비스를 이용할 수 없습니다. 잠시 후 다시 시도해 주세요.',
        });
      }
      return AuthSession.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw const AuthFailure('응답이 지연되고 있습니다. 다시 시도해 주세요.');
    } on http.ClientException {
      throw const AuthFailure('로그인 서버에 연결하지 못했습니다. 연결 상태를 확인해 주세요.');
    } on FormatException {
      throw const AuthFailure('로그인 응답을 확인하지 못했습니다. 다시 시도해 주세요.');
    }
  }

  void close() => _client.close();
}
