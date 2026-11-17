import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/core/router/osee_app.dart';
import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/features/categories/category_api.dart';
import 'package:beandoche_osee_frontend/features/clothes/garment_api.dart';
import 'package:beandoche_osee_frontend/features/clothes/models/catalog_garment.dart';
import 'package:beandoche_osee_frontend/features/clothes/models/garment_options.dart';
import 'package:beandoche_osee_frontend/features/fitting_room/fitting_catalog.dart';
import 'package:beandoche_osee_frontend/features/fitting_room/screens/fitting_page.dart';

import 'category_test.dart' show makeAuth;
import 'garment_fixtures.dart';
import 'fitting_fixtures.dart';

void main() {
  test('t1 상세·옵션·선택 API를 인증하고 mm를 cm로 표시한다', () async {
    final requests = <http.Request>[];
    final api = fittingApi(onRequest: requests.add);
    final detail = await api.details('token', 7);
    final selection = await api.selection('token', 7, 71, 711);
    expect(detail.options.variants.first.sizes.first.label, 'M');
    expect(selection.measurements.single.displayValue, '50 cm');
    expect(selection.measurements.single.basis, 'FLAT_WIDTH');
    expect(selection.measurementReady, isFalse);
    expect(selection.modelAvailable, isFalse);
    expect(
      requests.every((r) => r.headers['Authorization'] == 'Bearer token'),
      isTrue,
    );
    expect(requests.last.url.queryParameters, {
      'variantId': '71',
      'sizeId': '711',
    });
    api.close();
  });

  test('t2 상품 또는 사이즈가 다른 응답과 잘못된 혼용률을 거부한다', () async {
    final api = GarmentApi(
      client: MockClient(
        (_) async => garmentResponse(selectionJson(sizeId: 721)),
      ),
    );
    await expectLater(
      api.selection('token', 7, 71, 711),
      throwsA(isA<GarmentFailure>()),
    );
    api.close();
    expect(
      () => GarmentOptions.fromJson({
        ...optionsJson(),
        'materialStatus': 'KNOWN',
        'materials': [
          {'name': '면', 'percentage': 60},
        ],
      }),
      throwsFormatException,
    );
  });

  test('t3 담기·중복 취소·제거를 처리하고 목데이터를 사용하지 않는다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final catalog = FittingCatalog(auth: auth, api: fittingApi());
    expect(catalog.items, isEmpty);
    final item = CatalogGarment.fromJson(garmentJson());
    catalog.toggle(item);
    expect(catalog.items.length, 1);
    catalog.toggle(item);
    expect(catalog.items, isEmpty);
    catalog.toggle(item);
    catalog.toggle(CatalogGarment.fromJson(garmentJson(id: 8)));
    catalog.remove(8);
    expect(catalog.activeId, 7);
    catalog.dispose();
    auth.dispose();
  });

  test('t4 색상별 판매 사이즈만 선택하고 색상 변경 시 선택을 초기화한다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    var selectionCalls = 0;
    final catalog = FittingCatalog(
      auth: auth,
      api: fittingApi(
        onRequest: (r) {
          if (r.url.path.endsWith('/selection')) selectionCalls++;
        },
      ),
    );
    catalog.toggle(CatalogGarment.fromJson(garmentJson()));
    await catalog.loadActive();
    await catalog.chooseSize(712);
    expect(selectionCalls, 0);
    await catalog.chooseSize(711);
    expect(catalog.selection!.sizeId, 711);
    catalog.chooseVariant(72);
    expect(catalog.selectedSizeId, isNull);
    expect(catalog.selection, isNull);
    await catalog.chooseSize(711);
    expect(selectionCalls, 1);
    await catalog.chooseSize(721);
    expect(catalog.selection!.variantId, 72);
    catalog.dispose();
    auth.dispose();
  });

  test('t5 빠른 색상 변경은 이전 실측 응답을 무시한다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final pending = Completer<http.Response>();
    final api = GarmentApi(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/selection')) return pending.future;
        return garmentResponse(
          request.url.path.endsWith('/options') ? optionsJson() : detailJson(),
        );
      }),
    );
    final catalog = FittingCatalog(auth: auth, api: api);
    catalog.toggle(CatalogGarment.fromJson(garmentJson()));
    await catalog.loadActive();
    final load = catalog.chooseSize(711);
    catalog.chooseVariant(72);
    pending.complete(garmentResponse(selectionJson()));
    await load;
    expect(catalog.selection, isNull);
    expect(catalog.selectedVariantId, 72);
    catalog.dispose();
    auth.dispose();
  });

  test('t6 로그아웃 후 상세 응답이 와도 담긴 의류를 복원하지 않는다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final pending = Completer<http.Response>();
    final catalog = FittingCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient(
          (r) async => r.url.path.endsWith('/options')
              ? pending.future
              : garmentResponse(detailJson()),
        ),
      ),
    );
    catalog.toggle(CatalogGarment.fromJson(garmentJson()));
    final load = catalog.loadActive();
    await auth.logout();
    pending.complete(garmentResponse(optionsJson()));
    await load;
    expect(catalog.items, isEmpty);
    expect(catalog.detail, isNull);
    catalog.dispose();
    auth.dispose();
  });

  test('t7 상세 실패를 안전하게 표시하고 재시도한다', () async {
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    var fail = true;
    final catalog = FittingCatalog(
      auth: auth,
      api: GarmentApi(
        client: MockClient(
          (r) async => fail
              ? http.Response('private', 500)
              : garmentResponse(
                  r.url.path.endsWith('/options')
                      ? optionsJson()
                      : detailJson(),
                ),
        ),
      ),
    );
    catalog.toggle(CatalogGarment.fromJson(garmentJson()));
    await catalog.loadActive();
    expect(catalog.error, isNot(contains('private')));
    expect(catalog.detail, isNull);
    fail = false;
    await catalog.retry();
    expect(catalog.detail, isNotNull);
    catalog.dispose();
    auth.dispose();
  });

  testWidgets('t8 CLOTHES + 담기에서 피팅룸 옵션·실측까지 연결한다', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final store = OseeStore();
    await tester.pumpWidget(
      OseeApp(
        initialAuth: auth,
        initialStore: store,
        garmentApi: GarmentApi(
          client: MockClient(
            (_) async => garmentResponse(
              garmentPageJson(total: 1, items: [garmentJson()]),
            ),
          ),
        ),
        fittingApi: fittingApi(),
        categoryApi: CategoryApi(
          client: MockClient((_) async => http.Response('[]', 200)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CLOTHES'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('테스트 셔츠 피팅룸에 담기'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('테스트 셔츠 담기 취소'), findsOneWidget);
    await tester.tap(find.text('FITTING ROOM'));
    await tester.pumpAndSettle();
    expect(find.text('COLOR'), findsOneWidget);
    expect(find.text('SIZE'), findsOneWidget);
    final disabled = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'XL (선택 불가)'),
    );
    expect(disabled.onSelected, isNull);
    await tester.tap(find.widgetWithText(ChoiceChip, 'M'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('사이즈 정보'));
    await tester.tap(find.text('사이즈 정보'));
    await tester.pumpAndSettle();
    expect(find.text('가슴단면 · 50 cm'), findsOneWidget);
    expect(find.text('실측 검증 불가'), findsOneWidget);
    expect(find.text('3D 모델 미제공'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    store.dispose();
  });

  testWidgets('t9 모바일에서 피팅룸 패널과 빈 상태를 안전하게 표시한다', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = makeAuth();
    await auth.loginWithGoogle('test');
    final catalog = FittingCatalog(auth: auth, api: fittingApi());
    catalog.toggle(CatalogGarment.fromJson(garmentJson()));
    await catalog.loadActive();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FittingPage(catalog: catalog, open: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('COLOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    catalog.remove(7);
    await tester.pumpAndSettle();
    expect(find.text('담은 의류가 없습니다.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    auth.dispose();
  });
}
