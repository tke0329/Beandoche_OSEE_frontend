import 'dart:async';
import 'dart:convert';

import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';
import 'package:beandoche_osee_frontend/features/profile/body_profile.dart';
import 'package:beandoche_osee_frontend/features/profile/body_profile_controller.dart';
import 'package:beandoche_osee_frontend/features/profile/screens/body_setup_page.dart';
import 'package:beandoche_osee_frontend/features/fitting_room/fitting_catalog.dart';
import 'package:beandoche_osee_frontend/features/fitting_room/screens/fitting_page.dart';
import 'package:beandoche_osee_frontend/core/widgets/avatar_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'auth_test.dart' show sessionJson, profileJson, utf8Response;
import 'category_test.dart' show makeAuth;
import 'fitting_fixtures.dart' show fittingApi;

import 'package:beandoche_osee_frontend/core/router/osee_app.dart';
import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';

// Isolated test data, never used as a user's default measurements.
Map<String, Object?> bodyJson({String gender = 'FEMALE'}) => {
  'gender': gender,
  'bodyVersion': 1,
  'generationId': '00000000-0000-0000-0000-000000000001',
  'generationStatus': 'PENDING',
  'measurements': {
    'heightMm': 1650,
    'weightKg': 55.125,
    'chestCircumferenceMm': 850,
    'waistCircumferenceMm': 650,
    'hipCircumferenceMm': 900,
    'thighCircumferenceMm': 500,
    'inseamMm': 750,
  },
};

void main() {
  testWidgets('t9 저장 후 피팅룸으로 이동하고 앱 재진입 시 저장한 모델을 다시 불러온다', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    auth.showBodyStep = true;
    final store = OseeStore();
    await tester.runAsync(store.initialize);
    Map<String, Object?>? saved;
    var gets = 0;
    AuthApi api() => AuthApi(
      client: MockClient((request) async {
        if (request.method == 'PUT') {
          saved = jsonDecode(request.body) as Map<String, Object?>;
        } else {
          gets++;
        }
        return saved == null
            ? utf8Response('{"code":"BODY_PROFILE_REQUIRED"}', 404)
            : utf8Response(
                jsonEncode(bodyJson(gender: saved!['gender']! as String)),
                200,
              );
      }),
    );
    await tester.pumpWidget(
      OseeApp(initialAuth: auth, initialStore: store, bodyProfileApi: api()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('남성').last);
    await tester.pumpAndSettle();
    final values = ['165', '55.125', '85', '65', '90', '50', '75'];
    for (final entry in BodyMeasurement.values.indexed) {
      final input = find.byKey(ValueKey(entry.$2.key));
      await tester.ensureVisible(input);
      await tester.enterText(input, values[entry.$1]);
    }
    await tester.ensureVisible(find.text('저장하고 피팅룸 보기'));
    await tester.tap(find.text('저장하고 피팅룸 보기'));
    await tester.pumpAndSettle();
    expect(saved?['gender'], 'MALE');
    expect(saved?['heightMm'], 1650);
    expect(saved?['weightKg'], 55.125);
    expect(find.byType(FittingPage), findsOneWidget);
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).model,
      AvatarModel.male,
    );
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).heightMm,
      1650,
    );
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).weightKg,
      55.125,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      OseeApp(initialAuth: auth, initialStore: store, bodyProfileApi: api()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('FITTING ROOM'));
    await tester.pumpAndSettle();
    expect(gets, 2);
    expect(find.byType(FittingPage), findsOneWidget);
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).weightKg,
      55.125,
    );
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).model,
      AvatarModel.male,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    store.dispose();
  });

  testWidgets('t10 모델 저장 실패 시 피팅룸으로 이동하지 않고 재시도할 수 있다', (tester) async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final body = BodyProfileController(
      auth: auth,
      api: AuthApi(
        client: MockClient(
          (request) async => request.method == 'GET'
              ? utf8Response(jsonEncode(bodyJson()), 200)
              : utf8Response('{"code":"INTERNAL_ERROR"}', 500),
        ),
      ),
    );
    var saved = false;
    await tester.pumpWidget(
      BodyProfileScope(
        controller: body,
        child: MaterialApp(
          home: BodySetupPage(onNext: () {}, onSaved: () => saved = true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.text('저장하고 피팅룸 보기');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(saved, isFalse);
    expect(body.error, isNotNull);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, '저장하고 피팅룸 보기'),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    body.dispose();
    auth.dispose();
  });

  testWidgets('t7 계정의 남성 모델을 복원하고 성별 변경을 서버에 저장한다', (tester) async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    var gender = 'MALE';
    final body = BodyProfileController(
      auth: auth,
      api: AuthApi(
        client: MockClient((request) async {
          if (request.method == 'PUT') {
            gender =
                (jsonDecode(request.body) as Map<String, Object?>)['gender']!
                    as String;
          }
          return utf8Response(jsonEncode(bodyJson(gender: gender)), 200);
        }),
      ),
    );
    await body.load();
    final fitting = FittingCatalog(auth: auth, api: fittingApi());
    await tester.pumpWidget(
      BodyProfileScope(
        controller: body,
        child: MaterialApp(
          home: FittingPage(catalog: fitting, open: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).model,
      AvatarModel.male,
    );
    await tester.tap(find.text('여성'));
    await tester.pumpAndSettle();
    expect(gender, 'FEMALE');
    expect(body.profile!.gender, 'FEMALE');
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).model,
      AvatarModel.female,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    fitting.dispose();
    body.dispose();
    auth.dispose();
  });

  testWidgets('t8 계정 전환 시 폼의 이전 치수를 지우고 새 계정 정보를 조회한다', (tester) async {
    var userId = 42;
    final auth = AuthController(
      api: AuthApi(
        client: MockClient(
          (request) async => utf8Response(
            jsonEncode(
              request.method == 'GET'
                  ? {...profileJson(), 'userId': userId}
                  : {...sessionJson(), 'userId': userId},
            ),
            200,
          ),
        ),
      ),
    );
    await auth.loginWithGoogle('first');
    final body = BodyProfileController(
      auth: auth,
      api: AuthApi(
        client: MockClient(
          (_) async => userId == 42
              ? utf8Response(jsonEncode(bodyJson()), 200)
              : utf8Response('{"code":"BODY_PROFILE_REQUIRED"}', 404),
        ),
      ),
    );
    await tester.pumpWidget(
      BodyProfileScope(
        controller: body,
        child: MaterialApp(home: BodySetupPage(onNext: () {})),
      ),
    );
    await tester.pumpAndSettle();
    final height = find.byKey(const ValueKey('heightMm'));
    expect(tester.widget<TextFormField>(height).controller!.text, '165');
    userId = 99;
    await auth.restore();
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(height).controller!.text, isEmpty);
    expect(body.profile, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    body.dispose();
    auth.dispose();
  });

  test('t1 cm를 정수 mm로 변환하고 잘못된 입력을 거부한다', () {
    expect(BodyMeasurement.height.parseInput('165.1'), 1651);
    expect(BodyMeasurement.chest.parseInput('85'), 850);
    expect(BodyMeasurement.weight.parseInput('55.125'), 55.125);
    for (final text in ['', '-1', '0', 'NaN', 'Infinity', '1e3', '1.23']) {
      expect(BodyMeasurement.height.parseInput(text), isNull);
    }
    expect(BodyMeasurement.weight.parseInput('55.1234'), isNull);
    expect(BodyMeasurement.height.display(1650), '165');
    expect(BodyMeasurement.height.display(1651), '165.1');
  });

  test('t2 본인 인증으로 조회하고 cm가 아닌 mm와 kg를 저장한다', () async {
    final api = AuthApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/users/me/body-profile');
        expect(request.headers['Authorization'], 'Bearer owner-token');
        expect(request.url.hasQuery, isFalse);
        if (request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['gender'], 'FEMALE');
          expect(body['heightMm'], 1650);
          expect(body['weightKg'], 55.125);
          expect(body.containsKey('userId'), isFalse);
        }
        return utf8Response(jsonEncode(bodyJson()), 200);
      }),
    );
    final loaded = await api.bodyProfile('owner-token');
    final saved = await api.saveBodyProfile(
      'owner-token',
      'FEMALE',
      loaded!.measurements,
    );
    expect(saved.gender, 'FEMALE');
    api.close();
  });

  test('t3 미등록 404만 빈 상태로 처리하고 서버 상세를 노출하지 않는다', () async {
    final api = AuthApi(
      client: MockClient(
        (_) async => utf8Response('{"code":"BODY_PROFILE_REQUIRED"}', 404),
      ),
    );
    expect(await api.bodyProfile('token'), isNull);
    api.close();
    final failed = AuthApi(
      client: MockClient(
        (_) async => utf8Response(
          '{"code":"INTERNAL_ERROR","message":"private server details"}',
          500,
        ),
      ),
    );
    await expectLater(
      failed.bodyProfile('token'),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'safe message',
          isNot(contains('private')),
        ),
      ),
    );
    failed.close();
  });

  test('t4 로그아웃 후 도착한 응답은 다음 계정에 반영하지 않는다', () async {
    var userId = 42;
    final auth = AuthController(
      api: AuthApi(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/logout')) {
            return utf8Response('', 204);
          }
          return utf8Response(
            jsonEncode(
              request.method == 'GET'
                  ? {...profileJson(), 'userId': userId}
                  : {...sessionJson(), 'userId': userId},
            ),
            200,
          );
        }),
      ),
    );
    await auth.loginWithGoogle('first');
    final pending = Completer<http.Response>();
    final body = BodyProfileController(
      auth: auth,
      api: AuthApi(client: MockClient((_) => pending.future)),
    );
    final loading = body.load();
    await auth.logout();
    userId = 99;
    await auth.loginWithGoogle('second');
    pending.complete(utf8Response(jsonEncode(bodyJson()), 200));
    await loading;
    expect(body.profile, isNull);
    expect(body.loaded, isFalse);
    expect(body.loading, isFalse);
    body.dispose();
    auth.dispose();
  });

  test('t5 저장 실패 시 기존 본인 정보를 유지하고 성공을 반환하지 않는다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final body = BodyProfileController(
      auth: auth,
      api: AuthApi(
        client: MockClient(
          (request) async => request.method == 'GET'
              ? utf8Response(jsonEncode(bodyJson()), 200)
              : utf8Response('{"code":"INTERNAL_ERROR"}', 500),
        ),
      ),
    );
    await body.load();
    final previous = body.profile;
    expect(await body.save('MALE', previous!.measurements), isFalse);
    expect(body.profile, same(previous));
    expect(body.error, isNotNull);
    body.dispose();
    auth.dispose();
  });

  testWidgets('t6 저장된 치수를 cm로 복원하고 수정값을 본인 API에 저장한다', (tester) async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    Map<String, Object?>? saved;
    final body = BodyProfileController(
      auth: auth,
      api: AuthApi(
        client: MockClient((request) async {
          if (request.method == 'PUT') {
            saved = jsonDecode(request.body) as Map<String, Object?>;
          }
          return utf8Response(jsonEncode(bodyJson()), 200);
        }),
      ),
    );
    var done = false;
    await tester.pumpWidget(
      BodyProfileScope(
        controller: body,
        child: MaterialApp(home: BodySetupPage(onNext: () => done = true)),
      ),
    );
    await tester.pumpAndSettle();
    final height = find.byKey(const ValueKey('heightMm'));
    expect(tester.widget<TextFormField>(height).controller!.text, '165');
    await tester.enterText(height, '166.1');
    final save = find.text('신체정보 저장');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(saved?['heightMm'], 1661);
    expect(saved?['gender'], 'FEMALE');
    expect(done, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    body.dispose();
    auth.dispose();
  });

  testWidgets('t11 키와 몸무게를 미리보기에 전달하고 성별 선택 후에도 유지한다', (tester) async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final body = BodyProfileController(
      auth: auth,
      api: AuthApi(
        client: MockClient(
          (_) async => utf8Response(jsonEncode(bodyJson()), 200),
        ),
      ),
    );
    await tester.pumpWidget(
      BodyProfileScope(
        controller: body,
        child: MaterialApp(home: BodySetupPage(onNext: () {})),
      ),
    );
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('heightMm'));
    await tester.ensureVisible(input);
    await tester.enterText(input, '172.3');
    await tester.pumpAndSettle();
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).heightMm,
      1723,
    );
    final weight = find.byKey(const ValueKey('weightKg'));
    await tester.ensureVisible(weight);
    await tester.enterText(weight, '92.5');
    await tester.pumpAndSettle();
    expect(
      tester.widget<AvatarViewer>(find.byType(AvatarViewer)).weightKg,
      92.5,
    );
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('남성').last);
    await tester.pumpAndSettle();
    final preview = tester.widget<AvatarViewer>(find.byType(AvatarViewer));
    expect(preview.model, AvatarModel.male);
    expect(preview.heightMm, 1723);
    expect(preview.weightKg, 92.5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    body.dispose();
    auth.dispose();
  });
}
