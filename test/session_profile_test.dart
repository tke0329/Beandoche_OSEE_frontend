import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:beandoche_osee_frontend/core/router/osee_app.dart';
import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';
import 'package:beandoche_osee_frontend/features/profile/profile_avatar.dart';

import 'auth_test.dart' show sessionJson, profileJson, utf8Response;

void main() {
  testWidgets(
    't7 pending profile hover timer is harmless after logout removes the portal',
    (tester) async {
      final auth = AuthController(
        api: AuthApi(
          client: MockClient(
            (request) async => request.url.path.endsWith('/logout')
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
      await auth.restore();
      await tester.pumpWidget(OseeApp(initialAuth: auth, initialStore: store));
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byTooltip('마이페이지')));
      await tester.pumpAndSettle();
      await mouse.moveTo(Offset.zero);
      await auth.logout();
      await tester.pumpAndSettle();
      expect(find.byTooltip('로그인'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      store.dispose();
    },
  );
  testWidgets('t5 returning to the app restores the server cookie session', (
    tester,
  ) async {
    var restores = 0;
    final auth = AuthController(
      api: AuthApi(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/session')) {
            restores++;
            return utf8Response(jsonEncode(sessionJson()), 200);
          }
          return utf8Response(jsonEncode(profileJson()), 200);
        }),
      ),
    );
    final store = OseeStore();
    await tester.runAsync(store.initialize);
    await tester.pumpWidget(OseeApp(initialAuth: auth, initialStore: store));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(restores, 1);
    expect(auth.isAuthenticated, isTrue);
    expect(find.byTooltip('마이페이지'), findsOneWidget);
    expect(find.textContaining('회원 ID'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    store.dispose();
  });

  testWidgets(
    't6 default profile uses a basic person icon, not a model image',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfileAvatar()));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );

  test(
    't4 logout waits for an in-flight rotation before clearing the cookie',
    () async {
      final pending = Completer<http.Response>();
      var loggedOut = false;
      final auth = AuthController(
        api: AuthApi(
          client: MockClient((r) async {
            if (r.url.path.endsWith('/session')) return pending.future;
            if (r.url.path.endsWith('/logout')) {
              loggedOut = true;
              return utf8Response('', 204);
            }
            return utf8Response(jsonEncode(profileJson()), 200);
          }),
        ),
      );
      final restoring = auth.restore();
      final logout = auth.logout();
      expect(loggedOut, isFalse);
      pending.complete(utf8Response(jsonEncode(sessionJson()), 200));
      await restoring;
      await logout;
      expect(loggedOut, isTrue);
      expect(auth.session, isNull);
      auth.dispose();
    },
  );
  test('t0 cookie response and profile JSON decode safely', () async {
    final api = AuthApi(
      client: MockClient(
        (r) async => utf8Response(
          jsonEncode(r.method == 'GET' ? profileJson() : sessionJson()),
          200,
        ),
      ),
    );
    expect((await api.restore())!.userId, 42);
    expect((await api.profile('test')).nickname, '테스트회원');
    api.close();
  });
  test('t1 reload restores session through cookie API without storing refresh token in Dart', () async {
    final auth = AuthController(
      api: AuthApi(
        client: MockClient(
          (r) async => utf8Response(
            jsonEncode(r.method == 'GET' ? profileJson() : sessionJson()),
            200,
          ),
        ),
      ),
    );
    await auth.restore();
    expect(auth.isAuthenticated, isTrue);
    expect(auth.profile!.nickname, '테스트회원');
    auth.dispose();
  });

  testWidgets(
    't2 incomplete profile requires nickname then shows prepared body step',
    (tester) async {
      var completed = false;
      final auth = AuthController(
        api: AuthApi(
          client: MockClient((r) async {
            if (r.method == 'PUT') completed = true;
            if (r.url.path.endsWith('/nickname-availability')) {
              return utf8Response('{"available":true}', 200);
            }
            return utf8Response(
              jsonEncode(
                r.url.path.endsWith('/google')
                    ? sessionJson()
                    : profileJson(completed: completed),
              ),
              200,
            );
          }),
        ),
      );
      final store = OseeStore();
      await tester.runAsync(store.initialize);
      await tester.runAsync(() => auth.loginWithGoogle('test'));
      await tester.pumpWidget(OseeApp(initialAuth: auth, initialStore: store));
      await tester.pumpAndSettle();
      expect(find.text('프로필 만들기'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '테스트회원');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('다음'));
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('아직 준비 중입니다'), findsOneWidget);
      expect(find.text('Before you buy,'), findsNothing);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('Before you buy,'), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byTooltip('마이페이지')));
      await tester.pumpAndSettle();
      expect(find.text('테스트회원'), findsWidgets);
      expect(find.text('마이페이지로 이동'), findsOneWidget);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      store.dispose();
    },
  );

  test('t3 logout ends session and clears private profile state', () async {
    final auth = AuthController(
      api: AuthApi(
        client: MockClient(
          (r) async => r.url.path.endsWith('/logout')
              ? utf8Response('', 204)
              : utf8Response(
                  jsonEncode(r.method == 'GET' ? profileJson() : sessionJson()),
                  200,
                ),
        ),
      ),
    );
    await auth.restore();
    await auth.logout();
    expect(auth.session, isNull);
    expect(auth.profile, isNull);
    auth.dispose();
  });
}
