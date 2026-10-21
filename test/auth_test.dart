import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';

Map<String, Object> sessionJson() => {
  'userId': 42,
  'newUser': true,
  'tokenType': 'Bearer',
  'accessToken': 'test-access',
  'accessTokenExpiresAt': DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 15))
      .toIso8601String(),
  'refreshToken': 'test-refresh',
  'sessionExpiresAt': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 48))
      .toIso8601String(),
};

Map<String, Object?> profileJson({bool completed = true}) => {
  'userId': 42,
  'profileCompleted': completed,
  'nickname': completed ? '테스트회원' : null,
  'imageBase64': null,
  'nicknameNextChangeAt': null,
};

http.Response utf8Response(String body, int status) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('t1 sends Google ID token and parses service session', () async {
    final api = AuthApi(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/web/google');
        expect(jsonDecode(request.body), {'idToken': 'google-token'});
        expect(request.headers['Authorization'], isNull);
        return utf8Response(jsonEncode(sessionJson()), 200);
      }),
    );
    final session = await api.loginWithGoogle('google-token');
    expect(session.userId, 42);
    expect(session.accessToken, 'test-access');
  });

  for (final entry in [400, 401, 503].indexed) {
    final status = entry.$2;
    test(
      't${entry.$1 + 2} maps unsafe server errors ($status) to safe messages',
      () async {
        final api = AuthApi(
          baseUrl: 'http://localhost:8080',
          client: MockClient(
            (_) async => utf8Response('secret-stack-trace', status),
          ),
        );
        await expectLater(
          api.loginWithGoogle('google-token'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.message,
              'message',
              isNot(contains('secret')),
            ),
          ),
        );
      },
    );
  }

  test('t5 malformed successful response is rejected', () async {
    final api = AuthApi(
      baseUrl: 'http://localhost:8080',
      client: MockClient((_) async => utf8Response('{}', 200)),
    );
    await expectLater(
      api.loginWithGoogle('google-token'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('t6 duplicate login is ignored while exchanging tokens', () async {
    final result = Completer<http.Response>();
    var calls = 0;
    final auth = AuthController(
      api: AuthApi(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) {
          if (request.method == 'GET') {
            return Future.value(utf8Response(jsonEncode(profileJson()), 200));
          }
          calls++;
          return result.future;
        }),
      ),
    );
    final first = auth.loginWithGoogle('google-token');
    await auth.loginWithGoogle('google-token');
    expect(auth.busy, isTrue);
    expect(auth.session, isNull);
    result.complete(utf8Response(jsonEncode(sessionJson()), 200));
    await first;
    expect(calls, 1);
    expect(auth.isAuthenticated, isTrue);
    auth.dispose();
  });

  test('t7 handled network failure keeps user signed out', () async {
    final auth = AuthController(
      api: AuthApi(
        baseUrl: 'http://localhost:8080',
        client: MockClient(
          (_) async => throw http.ClientException('sensitive transport detail'),
        ),
      ),
    );
    await auth.loginWithGoogle('google-token');
    expect(auth.isAuthenticated, isFalse);
    expect(auth.busy, isFalse);
    expect(auth.error, isNotNull);
    expect(auth.error, isNot(contains('sensitive')));
    auth.dispose();
  });

  test('t8 timeout becomes a retryable safe failure', () async {
    final pending = Completer<http.Response>();
    final api = AuthApi(
      baseUrl: 'http://localhost:8080',
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => pending.future),
    );
    await expectLater(
      api.loginWithGoogle('test-token'),
      throwsA(
        isA<AuthFailure>().having((e) => e.message, 'message', contains('지연')),
      ),
    );
    pending.complete(utf8Response('{}', 500));
    api.close();
  });

  test('t9 expired service token never authenticates the user', () async {
    final json = sessionJson();
    json['accessTokenExpiresAt'] = DateTime.now()
        .subtract(const Duration(seconds: 1))
        .toUtc()
        .toIso8601String();
    final auth = AuthController(
      api: AuthApi(
        baseUrl: 'http://localhost:8080',
        client: MockClient((_) async => utf8Response(jsonEncode(json), 200)),
      ),
    );
    await auth.loginWithGoogle('test-token');
    expect(auth.isAuthenticated, isFalse);
    expect(auth.error, isNotNull);
    auth.dispose();
  });

  test(
    't10 late response after disposal does not restore authentication',
    () async {
      final pending = Completer<http.Response>();
      final auth = AuthController(
        api: AuthApi(
          baseUrl: 'http://localhost:8080',
          client: MockClient((_) => pending.future),
        ),
      );
      final login = auth.loginWithGoogle('test-token');
      auth.dispose();
      pending.complete(utf8Response(jsonEncode(sessionJson()), 200));
      await login;
      expect(auth.session, isNull);
    },
  );
}
