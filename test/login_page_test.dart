import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/core/router/osee_app.dart';
import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';
import 'package:beandoche_osee_frontend/features/auth/login_page.dart';

import 'auth_test.dart' show sessionJson, profileJson, utf8Response;

void main() {
  testWidgets(
    't1 signed-out launch shows public home and profile login entry',
    (tester) async {
      final auth = AuthController(
        api: AuthApi(client: MockClient((_) async => utf8Response('', 204))),
      );
      addTearDown(auth.dispose);
      final store = OseeStore();
      await tester.runAsync(store.initialize);
      addTearDown(store.dispose);
      await tester.pumpWidget(OseeApp(initialAuth: auth, initialStore: store));
      await tester.pumpAndSettle();
      expect(find.text('Before you buy,'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      await tester.tap(find.byTooltip('로그인'));
      await tester.pumpAndSettle();
      expect(find.text('나에게 맞는 옷을 만나는 시작'), findsOneWidget);
      await tester.tap(find.text('홈으로 돌아가기'));
      await tester.pumpAndSettle();
      expect(find.text('Before you buy,'), findsOneWidget);
      await tester.tap(find.text('WARDROBE').last);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('t2 rejected login displays safe retry message', (tester) async {
    final auth = AuthController(
      api: AuthApi(
        baseUrl: 'http://localhost:8080',
        client: MockClient((_) async => utf8Response('private-detail', 401)),
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
          (request) async => request.url.path.endsWith('/session')
              ? utf8Response('', 204)
              : utf8Response(
                  jsonEncode(
                    request.method == 'GET' ? profileJson() : sessionJson(),
                  ),
                  200,
                ),
        ),
      ),
    );
    final store = OseeStore();
    await tester.runAsync(store.initialize);
    await tester.pumpWidget(OseeApp(initialStore: store, initialAuth: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('로그인'));
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
    expect(find.textContaining('회원 ID'), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('홈으로 돌아가기'));
    await tester.tap(find.text('홈으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('Before you buy,'), findsOneWidget);
    await tester.pump(const Duration(minutes: 16));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Before you buy,'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    store.dispose();
  });

  testWidgets('t4 small screen login has no layout overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = AuthController(
      api: AuthApi(client: MockClient((_) async => utf8Response('', 204))),
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
