import 'dart:convert';
import 'dart:async';

import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';
import 'package:beandoche_osee_frontend/features/auth/login_page.dart';
import 'package:beandoche_osee_frontend/features/profile/screens/profile_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'auth_test.dart' show sessionJson, profileJson, utf8Response;

void main() {
  testWidgets(
    't5 stale availability response cannot enable an invalid nickname',
    (tester) async {
      final pending = Completer<http.Response>();
      final auth = AuthController(
        api: AuthApi(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/nickname-availability'))
              return pending.future;
            return utf8Response(
              jsonEncode(
                request.method == 'GET'
                    ? profileJson(completed: false)
                    : sessionJson(),
              ),
              200,
            );
          }),
        ),
      );
      await auth.loginWithGoogle('test');
      await tester.pumpWidget(
        MaterialApp(home: ProfileFormPage(auth: auth, initial: true)),
      );
      await tester.enterText(find.byType(TextFormField), 'valid_name');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextFormField), '!');
      pending.complete(utf8Response('{"available":true}', 200));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '다음'))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.errorText,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
  testWidgets('t1 empty initial nickname is submitted for server generation', (
    tester,
  ) async {
    var saves = 0;
    final auth = AuthController(
      api: AuthApi(
        client: MockClient((request) async {
          if (request.method == 'PUT') {
            saves++;
            final profile = profileJson()..['nickname'] = 'OSEE_123456789';
            return utf8Response(jsonEncode(profile), 200);
          }
          return utf8Response(
            jsonEncode(
              request.method == 'GET'
                  ? profileJson(completed: false)
                  : sessionJson(),
            ),
            200,
          );
        }),
      ),
    );
    await auth.loginWithGoogle('test');
    await tester.pumpWidget(
      MaterialApp(home: ProfileFormPage(auth: auth, initial: true)),
    );
    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(auth.profile!.nickname, 'OSEE_123456789');
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets(
    't2 duplicate nickname is shown under the field and clears on edit',
    (tester) async {
      final auth = AuthController(
        api: AuthApi(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/nickname-availability')) {
              return utf8Response(
                jsonEncode(
                  request.url.queryParameters['nickname'] == 'taken_name'
                      ? {'available': false, 'code': 'NICKNAME_ALREADY_EXISTS'}
                      : {'available': true},
                ),
                200,
              );
            }
            if (request.method == 'PUT') {
              return utf8Response(
                jsonEncode({
                  'code': 'NICKNAME_ALREADY_EXISTS',
                  'message': 'private',
                  'fieldErrors': [],
                }),
                409,
              );
            }
            return utf8Response(
              jsonEncode(
                request.method == 'GET'
                    ? profileJson(completed: false)
                    : sessionJson(),
              ),
              200,
            );
          }),
        ),
      );
      await auth.loginWithGoogle('test');
      await tester.pumpWidget(
        MaterialApp(home: ProfileFormPage(auth: auth, initial: true)),
      );
      await tester.enterText(find.byType(TextFormField), 'taken_name');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('다음'));
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '다음'))
            .onPressed,
        isNull,
      );
      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(decoration.errorText, '중복된 닉네임입니다.');
      expect(find.textContaining('private'), findsNothing);
      await tester.enterText(find.byType(TextFormField), 'new_name');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('중복된 닉네임입니다.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );

  testWidgets('t3 Kakao button uses the shared 40 pixel pill layout', (
    tester,
  ) async {
    final auth = AuthController(
      api: AuthApi(client: MockClient((_) async => utf8Response('', 204))),
    );
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('kakao-login-button'));
    expect(tester.getSize(button).height, 40);
    expect(tester.getSize(button).width, lessThanOrEqualTo(400));
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets(
    't4 prohibited and malformed nicknames disable Next with red field errors',
    (tester) async {
      final auth = AuthController(
        api: AuthApi(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/nickname-availability')) {
              return utf8Response(
                '{"available":false,"code":"NICKNAME_NOT_ALLOWED"}',
                200,
              );
            }
            return utf8Response(
              jsonEncode(
                request.method == 'GET'
                    ? profileJson(completed: false)
                    : sessionJson(),
              ),
              200,
            );
          }),
        ),
      );
      await auth.loginWithGoogle('test');
      await tester.pumpWidget(
        MaterialApp(home: ProfileFormPage(auth: auth, initial: true)),
      );
      for (final value in ['a!', 'FUCK', '시발', '병신', 'sex']) {
        await tester.enterText(find.byType(TextFormField), value);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        final decoration = tester
            .widget<TextField>(find.byType(TextField))
            .decoration!;
        expect(decoration.errorText, isNotNull);
        expect(decoration.errorStyle!.color, const Color(0xffb3261e));
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, '다음'))
              .onPressed,
          isNull,
        );
      }
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
