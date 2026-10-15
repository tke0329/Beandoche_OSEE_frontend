import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';
import 'package:beandoche_osee_frontend/features/auth/kakao_gateway.dart';
import 'package:beandoche_osee_frontend/features/auth/login_page.dart';
import 'auth_test.dart' show sessionJson;

class FakeKakaoGateway implements KakaoGateway {
  FakeKakaoGateway({this.failure});
  final AuthFailure? failure;
  @override Future<AuthSession> login() async {
    if (failure != null) throw failure!;
    return AuthSession.fromJson(sessionJson());
  }
  @override void cancel() {}
}

void main() {
  test('t1 valid Kakao result uses the existing authenticated session model', () {
    final session = decodeKakaoMessage({'type': 'osee:kakao-login', 'result': {'ok': true, 'session': sessionJson()}});
    expect(session.userId, 42);
  });
  test('t2 malformed or unrelated result cannot authenticate a user', () {
    expect(() => decodeKakaoMessage({'type': 'unrelated'}), throwsA(isA<AuthFailure>()));
    expect(() => decodeKakaoMessage({'type': 'osee:kakao-login', 'result': {'ok': true, 'session': {}}}), throwsA(isA<AuthFailure>()));
  });
  test('t3 provider error details are replaced by safe messages', () {
    expect(() => decodeKakaoMessage({'type': 'osee:kakao-login', 'result': {'ok': false, 'code': 'secret-provider-detail'}}), throwsA(isA<AuthFailure>().having((e) => e.message, 'message', isNot(contains('secret')))));
  });
  testWidgets('t4 Kakao button authenticates through the shared controller', (tester) async {
    final auth = AuthController(kakaoGateway: FakeKakaoGateway());
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isTrue);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
  testWidgets('t5 cancellation is handled without a framework exception', (tester) async {
    final auth = AuthController(kakaoGateway: FakeKakaoGateway(failure: const AuthFailure('카카오 로그인을 취소했습니다. 다시 시도할 수 있습니다.')));
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isFalse);
    expect(find.textContaining('취소했습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
