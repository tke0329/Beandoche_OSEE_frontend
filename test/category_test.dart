import 'package:flutter/gestures.dart';
import 'package:beandoche_osee_frontend/core/router/osee_app.dart';
import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';
import 'package:beandoche_osee_frontend/features/categories/category_api.dart';
import 'package:beandoche_osee_frontend/features/categories/category_catalog.dart';
import 'package:beandoche_osee_frontend/features/categories/category_panel.dart';

import 'auth_test.dart' show sessionJson, profileJson, utf8Response;

List<Object> treeJson() => [
  {
    'id': 2,
    'code': 'OUTERWEAR',
    'name': '아우터',
    'children': [
      {'id': 21, 'code': 'ZIP_UP_HOODIE', 'name': '후드 집업', 'children': []},
    ],
  },
  {
    'id': 1,
    'code': 'TOP',
    'name': '상의',
    'children': [
      {
        'id': 11,
        'code': 'LONG_SLEEVE_T_SHIRT',
        'name': '긴소매 티셔츠',
        'children': [],
      },
    ],
  },
];

AuthController makeAuth() => AuthController(
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

void main() {
  testWidgets('t10 데스크톱에서는 CLOTHES hover에 전체 분류와 하위 목록을 펼친다', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final store = OseeStore();
    final api = CategoryApi(
      client: MockClient(
        (_) async => utf8Response(jsonEncode(treeJson()), 200),
      ),
    );
    await tester.pumpWidget(
      OseeApp(initialAuth: auth, initialStore: store, categoryApi: api),
    );
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('CLOTHES')));
    await tester.pumpAndSettle();
    expect(find.text('상의'), findsOneWidget);
    expect(find.text('아우터'), findsOneWidget);
    expect(find.text('긴소매 티셔츠'), findsOneWidget);
    expect(find.text('후드 집업'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text('후드 집업'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 카테고리의 상품은 준비 중입니다.'), findsOneWidget);
    expect(find.text('상의'), findsNothing);
    expect(find.text('후드 집업'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await mouse.removePointer();
    auth.dispose();
    store.dispose();
  });

  test('t1 인증 헤더와 서버의 계층 및 순서를 보존한다', () async {
    final api = CategoryApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/categories');
        expect(request.headers['Authorization'], 'Bearer test-access');
        return utf8Response(jsonEncode(treeJson()), 200);
      }),
    );
    addTearDown(api.close);
    final result = await api.fetch('test-access');
    expect(result.map((c) => c.code), ['OUTERWEAR', 'TOP']);
    expect(result.first.children.single.name, '후드 집업');
    expect(result.first.children.single.children, isEmpty);
  });

  for (final status in [401, 403, 500]) {
    test('t2-$status 서버 오류 본문을 노출하지 않는다', () async {
      final api = CategoryApi(
        client: MockClient((_) async => http.Response('private-stack', status)),
      );
      addTearDown(api.close);
      await expectLater(
        api.fetch('token'),
        throwsA(
          isA<CategoryFailure>().having(
            (e) => e.message,
            '안전한 메시지',
            isNot(contains('private')),
          ),
        ),
      );
    });
  }

  test('t3 잘못된 응답 구조와 네트워크 오류를 처리한다', () async {
    for (final body in ['{}', '[{"id":1}]', 'invalid']) {
      final api = CategoryApi(
        client: MockClient((_) async => utf8Response(body, 200)),
      );
      await expectLater(api.fetch('token'), throwsA(isA<CategoryFailure>()));
      api.close();
    }
    final api = CategoryApi(
      client: MockClient((_) async => throw http.ClientException('private')),
    );
    addTearDown(api.close);
    await expectLater(api.fetch('token'), throwsA(isA<CategoryFailure>()));
  });

  test('t4 지연 응답은 안전한 시간 초과 오류로 변환한다', () async {
    final pending = Completer<http.Response>();
    final api = CategoryApi(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => pending.future),
    );
    addTearDown(api.close);
    await expectLater(api.fetch('token'), throwsA(isA<CategoryFailure>()));
    pending.complete(utf8Response('[]', 200));
  });

  test('t5 로그아웃 후 도착한 응답은 카테고리를 복원하지 않는다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final pending = Completer<http.Response>();
    final catalog = CategoryCatalog(
      auth: auth,
      api: CategoryApi(client: MockClient((_) => pending.future)),
    );
    final load = catalog.load();
    await auth.logout();
    pending.complete(utf8Response(jsonEncode(treeJson()), 200));
    await load;
    expect(catalog.categories, isEmpty);
    expect(catalog.needsLogin, isTrue);
    catalog.dispose();
    auth.dispose();
  });

  testWidgets('t6 로딩과 서버 카테고리 표시 및 하위 선택을 지원한다', (tester) async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final pending = Completer<http.Response>();
    final catalog = CategoryCatalog(
      auth: auth,
      api: CategoryApi(client: MockClient((_) => pending.future)),
    );
    String? root;
    String? child;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryPanel(
            catalog: catalog,
            selected: 'OUTERWEAR',
            subcategory: null,
            onSelect: (value, [sub]) {
              root = value;
              child = sub;
            },
            onLogin: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(utf8Response(jsonEncode(treeJson()), 200));
    await tester.pumpAndSettle();
    expect(find.text('아우터'), findsOneWidget);
    expect(find.text('상의'), findsOneWidget);
    await tester.tap(find.text('후드 집업'));
    expect(root, 'OUTERWEAR');
    expect(child, 'ZIP_UP_HOODIE');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    auth.dispose();
  });

  testWidgets('t7 오류 재시도 후 빈 상태를 표시한다', (tester) async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    var calls = 0;
    final catalog = CategoryCatalog(
      auth: auth,
      api: CategoryApi(
        client: MockClient((_) async {
          calls++;
          return calls == 1
              ? utf8Response('private', 503)
              : utf8Response('[]', 200);
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryPanel(
            catalog: catalog,
            selected: 'all',
            subcategory: null,
            onSelect: (value, [sub]) {},
            onLogin: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('표시할 카테고리가 없습니다.'), findsOneWidget);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    auth.dispose();
  });

  testWidgets('t8 비로그인 상태에서는 요청하지 않고 로그인 경로를 제공한다', (tester) async {
    final auth = makeAuth();
    var calls = 0;
    var login = false;
    final catalog = CategoryCatalog(
      auth: auth,
      api: CategoryApi(
        client: MockClient((_) async {
          calls++;
          return utf8Response('[]', 200);
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryPanel(
            catalog: catalog,
            selected: 'all',
            subcategory: null,
            onSelect: (value, [sub]) {},
            onLogin: () => login = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인'));
    expect(login, isTrue);
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    auth.dispose();
  });

  testWidgets('t9 작은 화면과 많은 카테고리도 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final data = treeJson();
    (data.first as Map<String, Object>)['children'] = List.generate(
      22,
      (i) => {
        'id': 100 + i,
        'code': 'CHILD_$i',
        'name': '아우터 항목 $i',
        'children': [],
      },
    );
    final catalog = CategoryCatalog(
      auth: auth,
      api: CategoryApi(
        client: MockClient((_) async => utf8Response(jsonEncode(data), 200)),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryPanel(
              catalog: catalog,
              selected: 'OUTERWEAR',
              subcategory: null,
              onSelect: (value, [sub]) {},
              onLogin: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('아우터 항목 21'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    auth.dispose();
  });
}
