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
  'accessTokenExpiresAt': DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String(),
  'refreshToken': 'test-refresh',
  'sessionExpiresAt': DateTime.now().toUtc().add(const Duration(hours: 48)).toIso8601String(),
};

void main() {
  test('t1 sends Google ID token and parses service session', () async {
    final api = AuthApi(baseUrl: 'http://localhost:8080', client: MockClient((request) async {
      expect(request.url.path, '/api/auth/social/google');
      expect(jsonDecode(request.body), {'idToken': 'google-token'});
      expect(request.headers['Authorization'], isNull);
      return http.Response(jsonEncode(sessionJson()), 200);
    }));
    final session = await api.loginWithGoogle('google-token');
    expect(session.userId, 42);
    expect(session.accessToken, 'test-access');
  });

  for (final status in [400, 401, 503]) {
    test('t$status maps unsafe server errors to safe messages', () async {
      final api = AuthApi(baseUrl: 'http://localhost:8080', client: MockClient((_) async => http.Response('secret-stack-trace', status)));
      await expectLater(api.loginWithGoogle('google-token'), throwsA(isA<AuthFailure>().having((e) => e.message, 'message', isNot(contains('secret')))));
    });
  }

  test('t5 malformed successful response is rejected', () async {
    final api = AuthApi(baseUrl: 'http://localhost:8080', client: MockClient((_) async => http.Response('{}', 200)));
    await expectLater(api.loginWithGoogle('google-token'), throwsA(isA<AuthFailure>()));
  });

  test('t6 duplicate login is ignored while exchanging tokens', () async {
    final result = Completer<http.Response>();
    var calls = 0;
    final auth = AuthController(api: AuthApi(baseUrl: 'http://localhost:8080', client: MockClient((_) { calls++; return result.future; })));
    final first = auth.loginWithGoogle('google-token');
    await auth.loginWithGoogle('google-token');
    expect(auth.busy, isTrue);
    expect(auth.session, isNull);
    result.complete(http.Response(jsonEncode(sessionJson()), 200));
    await first;
    expect(calls, 1);
    expect(auth.isAuthenticated, isTrue);
    auth.dispose();
  });

  test('t7 handled network failure keeps user signed out', () async {
    final auth = AuthController(api: AuthApi(baseUrl: 'http://localhost:8080', client: MockClient((_) async => throw http.ClientException('sensitive transport detail'))));
    await auth.loginWithGoogle('google-token');
    expect(auth.isAuthenticated, isFalse);
    expect(auth.busy, isFalse);
    expect(auth.error, isNotNull);
    expect(auth.error, isNot(contains('sensitive')));
    auth.dispose();
  });
}
