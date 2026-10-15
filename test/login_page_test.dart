import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/core/router/osee_app.dart';
import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';
import 'package:beandoche_osee_frontend/features/auth/login_page.dart';

import 'auth_test.dart' show sessionJson;

void main() {
  testWidgets('t1 signed-out launch shows login before personal pages', (
    tester,
  ) async {
    await tester.pumpWidget(const OseeApp());
    await tester.pumpAndSettle();
    expect(find.text('나에게 맞는 옷을 만나는 시작'), findsOneWidget);
    expect(find.text('WARDROBE'), findsNothing);
    expect(find.text('Before you buy,'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('t2 rejected login displays safe retry message', (tester) async {
    final auth = AuthController(
      api: AuthApi(
        baseUrl: 'http://localhost:8080',
        client: MockClient((_) async => http.Response('private-detail', 401)),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.runAsync(() => auth.loginWithGoogle('invalid-token'));
    await tester.pumpAndSettle();
    expect(find.textContaining('다시 로그인해 주세요.'), findsOneWidget);
    expect(find.textContaining('private-detail'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('t3 backend login success opens existing home', (tester) async {
    final auth = AuthController(
      api: AuthApi(
        baseUrl: 'http://localhost:8080',
        client: MockClient(
          (_) async => http.Response(jsonEncode(sessionJson()), 200),
        ),
      ),
    );
    final store = OseeStore();
    await tester.runAsync(store.initialize);
    await tester.pumpWidget(OseeApp(initialStore: store, initialAuth: auth));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    final login = auth.loginWithGoogle('valid-token');
    await tester.pumpAndSettle();
    await login;
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Before you buy,'), findsOneWidget);
    await tester.tap(find.byTooltip('마이페이지'));
    await tester.pumpAndSettle();
    expect(find.text('내 계정'), findsOneWidget);
    expect(find.text('회원 ID: 42'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('홈으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('Before you buy,'), findsOneWidget);
    await tester.pump(const Duration(minutes: 16));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Before you buy,'), findsNothing);
    expect(find.textContaining('로그인이 만료되었습니다.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    store.dispose();
  });

  testWidgets('t4 small screen login has no layout overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const OseeApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
