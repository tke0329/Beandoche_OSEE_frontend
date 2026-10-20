import 'dart:convert';

import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/router/osee_app.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import 'auth_test.dart' show sessionJson, profileJson, utf8Response;

void main() {
  testWidgets(
    't1 withdrawal requires confirmation and clears private state after success',
    (tester) async {
      var requests = 0;
      final auth = AuthController(
        api: AuthApi(
          client: MockClient((request) async {
            if (request.method == 'DELETE') {
              requests++;
              expect(request.headers['Authorization'], startsWith('Bearer '));
              return utf8Response(
                '{"withdrawn":true,"googleUnlinkRequired":true,"kakaoUnlinkPending":false}',
                200,
              );
            }
            return utf8Response(
              jsonEncode(
                request.method == 'GET' ? profileJson() : sessionJson(),
              ),
              200,
            );
          }),
        ),
      );
      final store = OseeStore();
      await tester.runAsync(store.initialize);
      await auth.loginWithGoogle('test');
      await tester.pumpWidget(OseeApp(initialAuth: auth, initialStore: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('마이페이지'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('회원탈퇴'));
      await tester.tap(find.text('회원탈퇴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      await tester.tap(find.text('회원탈퇴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('탈퇴하기'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(auth.session, isNull);
      expect(auth.profile, isNull);
      expect(find.text('회원탈퇴가 완료되었습니다.'), findsOneWidget);
      expect(find.text('Google 계정 연결 설정 열기'), findsOneWidget);
      await tester.tap(find.text('홈으로 돌아가기'));
      await tester.pumpAndSettle();
      expect(find.text('Before you buy,'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      store.dispose();
    },
  );

  test('t2 withdrawal server failure keeps the session and exposes only a safe retry message', () async {
    final auth = AuthController(
      api: AuthApi(
        client: MockClient(
          (request) async => request.method == 'DELETE'
              ? utf8Response('private server trace', 503)
              : utf8Response(
                  jsonEncode(
                    request.method == 'GET' ? profileJson() : sessionJson(),
                  ),
                  200,
                ),
        ),
      ),
    );
    await auth.loginWithGoogle('test');
    expect(await auth.withdraw(), isFalse);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.error, isNot(contains('private')));
    expect(auth.withdrawalResult, isNull);
    auth.dispose();
  });
}
