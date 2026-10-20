import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../profile/profile_data.dart';
import 'credential_client_stub.dart'
    if (dart.library.js_interop) 'credential_client_web.dart'
    as transport;

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.status});
  final String message;
  final int? status;
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
      if (userId > 0 &&
          accessToken.isNotEmpty &&
          accessAt != null &&
          sessionAt != null &&
          accessAt.isAfter(DateTime.now()) &&
          !accessAt.isAfter(sessionAt)) {
        return AuthSession(
          userId: userId,
          newUser: newUser,
          accessToken: accessToken,
          accessTokenExpiresAt: accessAt,
          sessionExpiresAt: sessionAt,
        );
      }
    }
    throw const AuthFailure('로그인 응답을 확인하지 못했습니다. 다시 시도해 주세요.');
  }
}

class AuthApi {
  AuthApi({
    String? baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'OSEE_API_BASE_URL',
             defaultValue: 'http://localhost:8080',
           ),
       _client = client ?? transport.credentialClient();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<AuthSession> loginWithGoogle(String idToken) async {
    if (idToken.trim().isEmpty) {
      throw const AuthFailure('Google 인증을 다시 진행해 주세요.');
    }
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.scheme != 'https' &&
            !(base.scheme == 'http' &&
                ['localhost', '127.0.0.1', '::1'].contains(base.host)))) {
      throw const AuthFailure('로그인 서버 주소 설정을 확인해 주세요.');
    }
    try {
      final response = await _client
          .post(
            base.resolve('/api/auth/web/google'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(timeout);
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

  Uri _uri(String path) {
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.scheme != 'https' &&
            !(base.scheme == 'http' &&
                ['localhost', '127.0.0.1', '::1'].contains(base.host)))) {
      throw const AuthFailure('서버 주소 설정을 확인해 주세요.');
    }
    return base.resolve(path);
  }

  Future<T> _safe<T>(Future<T> Function() work) async {
    try {
      return await work().timeout(timeout);
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw const AuthFailure('응답이 지연되고 있습니다. 다시 시도해 주세요.');
    } on http.ClientException {
      throw const AuthFailure('서버에 연결하지 못했습니다. 연결 상태를 확인해 주세요.');
    } on FormatException {
      throw const AuthFailure('응답을 확인하지 못했습니다. 다시 시도해 주세요.');
    }
  }

  Object? _read(http.Response response) {
    if (response.statusCode == 204) return null;
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    String? code;
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map && json['code'] is String) code = json['code'] as String;
    } on FormatException {
      code = null;
    }
    throw AuthFailure(switch (code) {
      'NICKNAME_ALREADY_EXISTS' => '이미 사용 중인 닉네임입니다.',
      'NICKNAME_CHANGE_NOT_ALLOWED' =>
        '닉네임은 30일마다 변경할 수 있습니다. 다음 변경 가능 일시를 확인해 주세요.',
      'INVALID_NICKNAME' => '닉네임은 한글·영문·숫자·밑줄 2~20자로 입력해 주세요.',
      'INVALID_PROFILE_IMAGE' => '1MB 이하의 올바른 PNG 또는 JPEG 이미지를 선택해 주세요.',
      _ =>
        response.statusCode == 401
            ? '로그인이 만료되었습니다. 다시 로그인해 주세요.'
            : '요청을 처리하지 못했습니다. 다시 시도해 주세요.',
    }, status: response.statusCode);
  }

  Future<AuthSession?> restore() => _safe(() async {
    final body = _read(await _client.post(_uri('/api/auth/web/session')));
    return body == null ? null : AuthSession.fromJson(body);
  });

  Future<void> logout() => _safe(() async {
    _read(await _client.post(_uri('/api/auth/web/logout')));
  });

  Future<ProfileData> profile(String accessToken) => _safe(
    () async => ProfileData.fromJson(
      _read(
        await _client.get(
          _uri('/api/users/me'),
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      ),
    ),
  );

  Future<ProfileData> saveProfile(
    String accessToken,
    String nickname, {
    Uint8List? image,
    String? imageName,
    bool removeImage = false,
  }) => _safe(() async {
    final request = http.MultipartRequest('PUT', _uri('/api/users/me'))
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['nickname'] = nickname
      ..fields['removeImage'] = removeImage.toString();
    if (image != null) {
      final name = imageName ?? 'avatar.png';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          image,
          filename: name,
          contentType: MediaType(
            'image',
            name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg',
          ),
        ),
      );
    }
    return ProfileData.fromJson(
      _read(await http.Response.fromStream(await _client.send(request))),
    );
  });
}
