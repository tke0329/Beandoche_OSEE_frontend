import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/features/clothes/garment_api.dart';
import 'package:beandoche_osee_frontend/features/clothes/garment_catalog.dart';
import 'package:beandoche_osee_frontend/features/clothes/widgets/garment_list.dart';

import 'category_test.dart' show makeAuth;
import 'garment_fixtures.dart';

void main() {
  test('t1 인증 헤더와 선택 카테고리·페이지·최신순을 전달한다', () async {
    final api = GarmentApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/garments');
        expect(request.url.queryParameters, {
          'categoryCode': 'SHIRT',
          'page': '2',
          'size': '20',
          'sort': 'LATEST',
        });
        expect(request.headers['Authorization'], 'Bearer token');
        return garmentResponse(
          garmentPageJson(page: 2, total: 41, items: [garmentJson()]),
        );
      }),
    );
    addTearDown(api.close);
    final result = await api.fetch('token', categoryCode: 'SHIRT', page: 2);
    expect(result.content.single.name, '테스트 셔츠');
    expect(result.totalElements, 41);
    expect(result.totalPages, 3);
  });

  test('t2 전체 조회는 카테고리 코드를 생략한다', () async {
    final api = GarmentApi(
      client: MockClient((request) async {
        expect(
          request.url.queryParameters.containsKey('categoryCode'),
          isFalse,
        );
        return garmentResponse(garmentPageJson());
      }),
    );
    addTearDown(api.close);
    expect((await api.fetch('token')).content, isEmpty);
  });

  for (final status in [401, 403, 404, 500]) {
    test('t3-$status 오류 본문 대신 안전한 메시지와 상태를 전달한다', () async {
      final api = GarmentApi(
        client: MockClient((_) async => http.Response('private-stack', status)),
      );
      addTearDown(api.close);
      await expectLater(
        api.fetch('token'),
        throwsA(
          isA<GarmentFailure>()
              .having((e) => e.status, '상태', status)
              .having((e) => e.message, '메시지', isNot(contains('private'))),
        ),
      );
    });
  }

  test('t4 잘못된 응답·페이지·상품 필드를 안전한 오류로 변환한다', () async {
    for (final body in [
      '{}',
      'invalid',
      jsonEncode(garmentPageJson(page: 1)),
      jsonEncode(
        garmentPageJson(
          total: 1,
          items: [
            {'id': 1},
          ],
        ),
      ),
      jsonEncode({...garmentPageJson(), 'totalPages': -1}),
    ]) {
      final api = GarmentApi(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(api.fetch('token'), throwsA(isA<GarmentFailure>()));
      api.close();
    }
  });

  test('t5 네트워크 실패와 시간 초과를 처리한다', () async {
    final api = GarmentApi(
      client: MockClient((_) async => throw http.ClientException('private')),
    );
    await expectLater(api.fetch('token'), throwsA(isA<GarmentFailure>()));
    api.close();
    final pending = Completer<http.Response>();
    final delayed = GarmentApi(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => pending.future),
    );
    await expectLater(delayed.fetch('token'), throwsA(isA<GarmentFailure>()));
    pending.complete(garmentResponse(garmentPageJson()));
    delayed.close();
  });

  test('t6 비로그인 또는 잘못된 서버 주소에는 요청을 보내지 않는다', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return garmentResponse(garmentPageJson());
    });
    final api = GarmentApi(client: client);
    await expectLater(api.fetch(''), throwsA(isA<GarmentFailure>()));
    final unsafe = GarmentApi(client: client, baseUrl: 'http://remote.example');
    await expectLater(unsafe.fetch('token'), throwsA(isA<GarmentFailure>()));
    expect(calls, 0);
    api.close();
  });

  test('t7 상대 이미지 주소를 해석하고 잘못된 주소는 대체 표시한다', () {
    final api = GarmentApi(baseUrl: 'http://localhost:8080');
    addTearDown(api.close);
    expect(
      api.imageUrl('/images/shirt.jpg'),
      'http://localhost:8080/images/shirt.jpg',
    );
    expect(
      api.imageUrl('https://cdn.example/shirt.jpg'),
      'https://cdn.example/shirt.jpg',
    );
    for (final value in [
      '',
      'javascript:alert(1)',
      'file:///tmp/img',
      'https://user:pass@cdn.example/img',
    ]) {
      expect(api.imageUrl(value), isNull);
    }
  });

  test('t8 빠른 카테고리 전환에서 오래된 응답을 무시한다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final first = Completer<http.Response>();
    final second = Completer<http.Response>();
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient(
          (r) => r.url.queryParameters['categoryCode'] == 'TOP'
              ? first.future
              : second.future,
        ),
      ),
    );
    final old = catalog.load(categoryCode: 'TOP', page: 1);
    final latest = catalog.load(categoryCode: 'PANTS');
    second.complete(
      garmentResponse(
        garmentPageJson(total: 1, items: [garmentJson(name: '바지')]),
      ),
    );
    await latest;
    first.complete(
      garmentResponse(
        garmentPageJson(page: 1, total: 21, items: [garmentJson(name: '상의')]),
      ),
    );
    await old;
    expect(catalog.data!.content.single.name, '바지');
    expect(catalog.page, 0);
    expect(catalog.categoryCode, 'PANTS');
    catalog.dispose();
    auth.dispose();
  });

  test('t9 로그아웃 후 지연 응답이 도착해도 상품을 복원하지 않는다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final pending = Completer<http.Response>();
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(client: MockClient((_) => pending.future)),
    );
    final load = catalog.load();
    await auth.logout();
    pending.complete(
      garmentResponse(garmentPageJson(total: 1, items: [garmentJson()])),
    );
    await load;
    expect(catalog.data, isNull);
    expect(catalog.needsLogin, isTrue);
    catalog.dispose();
    auth.dispose();
  });

  test('t10 dispose 이후 지연 응답을 무시한다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final pending = Completer<http.Response>();
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(client: MockClient((_) => pending.future)),
    );
    final load = catalog.load();
    catalog.dispose();
    pending.complete(garmentResponse(garmentPageJson()));
    await load;
    auth.dispose();
  });

  testWidgets('t11 상품 카드·페이지 이동·카테고리 전환을 연결한다', (tester) async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final requests = <Uri>[];
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient((r) async {
          requests.add(r.url);
          final page = int.parse(r.url.queryParameters['page']!);
          return garmentResponse(
            garmentPageJson(
              page: page,
              total: 21,
              items: [garmentJson(name: '상품 ${page + 1}')],
            ),
          );
        }),
      ),
    );
    Widget screen(String? code) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: GarmentList(
            catalog: catalog,
            categoryCode: code,
            onLogin: () {},
          ),
        ),
      ),
    );
    await tester.pumpWidget(screen(null));
    await tester.pumpAndSettle();
    expect(find.text('상품 1'), findsOneWidget);
    expect(find.text('총 21개 · 최신 등록순'), findsOneWidget);
    expect(find.text('이미지 없음'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '이전 페이지'))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('다음 페이지'));
    await tester.tap(find.text('다음 페이지'));
    await tester.pumpAndSettle();
    expect(find.text('상품 2'), findsOneWidget);
    expect(requests.last.queryParameters['page'], '1');
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '다음 페이지'))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(screen('SHIRT'));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['categoryCode'], 'SHIRT');
    expect(requests.last.queryParameters['page'], '0');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    auth.dispose();
  });

  testWidgets('t12 로딩·오류·재시도·빈 목록을 표시한다', (tester) async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final pending = Completer<http.Response>();
    var calls = 0;
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient((_) {
          calls++;
          return calls == 1
              ? pending.future
              : Future.value(garmentResponse(garmentPageJson()));
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GarmentList(
            catalog: catalog,
            categoryCode: null,
            onLogin: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('상품을 불러오는 중입니다.'), findsOneWidget);
    pending.complete(http.Response('private', 500));
    await tester.pumpAndSettle();
    expect(find.text('상품 다시 시도'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
    await tester.tap(find.text('상품 다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 상품이 없습니다.'), findsOneWidget);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    auth.dispose();
  });

  testWidgets('t13 비로그인 상태에서 상품 요청 없이 로그인 경로를 제공한다', (tester) async {
    final auth = makeAuth();
    var calls = 0;
    var login = false;
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient((_) async {
          calls++;
          return garmentResponse(garmentPageJson());
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GarmentList(
            catalog: catalog,
            categoryCode: null,
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

  testWidgets('t14 모바일에서 큰 글자와 긴 상품명도 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient(
          (_) async => garmentResponse(
            garmentPageJson(
              total: 2,
              items: [
                garmentJson(name: '아주 긴 상품명을 가진 테스트 의류입니다'),
                garmentJson(id: 8),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 740),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GarmentList(
                  catalog: catalog,
                  categoryCode: null,
                  onLogin: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('테스트 셔츠'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    auth.dispose();
  });
  test('t15 401 이후 재시도는 세션 복원 후 상품을 다시 조회한다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    var calls = 0;
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('private', 401)
              : garmentResponse(garmentPageJson());
        }),
      ),
    );
    await catalog.load();
    expect(catalog.error, isNotNull);
    await catalog.retry();
    expect(catalog.error, isNull);
    expect(catalog.data!.content, isEmpty);
    expect(calls, 2);
    catalog.dispose();
    auth.dispose();
  });

  testWidgets('t16 이미지 로딩 실패는 오류 없이 대체 화면으로 처리한다', (tester) async {
    debugNetworkImageHttpClientProvider = () => _FailingImageClient();
    addTearDown(() => debugNetworkImageHttpClientProvider = null);
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final catalog = GarmentCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient(
          (_) async => garmentResponse(
            garmentPageJson(
              total: 1,
              items: [garmentJson(image: 'https://cdn.example/missing.jpg')],
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GarmentList(
              catalog: catalog,
              categoryCode: null,
              onLogin: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('이미지 없음'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    debugNetworkImageHttpClientProvider = null;
    catalog.dispose();
    auth.dispose();
  });
}

class _FailingImageClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      throw const HttpException('test image failure');
}
