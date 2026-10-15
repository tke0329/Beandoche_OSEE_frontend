import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_api.dart';
import 'package:beandoche_osee_frontend/features/auth/auth_controller.dart';

import 'auth_test.dart' show sessionJson;

import 'package:beandoche_osee_frontend/core/router/osee_app.dart';
import 'package:beandoche_osee_frontend/features/clothes/screens/clothes_page.dart';
import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog and fitting state support an outfit round trip', () async {
    final store = OseeStore();
    await store.initialize();

    expect(store.catalog.length, 18);
    expect(store.fittingIds, ['vintage-tee', 'leather-pants']);

    store.size('vintage-tee', 'S');
    store.color('vintage-tee', 'blue');
    store.saveOutfit('테스트 착장', [...store.fittingIds]);
    final outfit = store.outfits.first;

    store.toggleFitting('vintage-tee');
    store.size('vintage-tee', 'L');
    store.loadOutfit(outfit);

    expect(store.fittingIds, ['vintage-tee', 'leather-pants']);
    expect(store.settings['vintage-tee']!.size, 'S');
    expect(store.settings['vintage-tee']!.colorId, 'blue');
  });

  testWidgets('home opens the clothes catalog', (tester) async {
    final store = OseeStore();
    await tester.runAsync(store.initialize);
    final auth = AuthController(
      api: AuthApi(
        baseUrl: 'http://localhost:8080',
        client: MockClient(
          (_) async => http.Response(jsonEncode(sessionJson()), 200),
        ),
      ),
    );
    await tester.runAsync(() => auth.loginWithGoogle('test-google-token'));
    await tester.pumpWidget(OseeApp(initialStore: store, initialAuth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Before you buy,'), findsOneWidget);
    await tester.tap(find.text('CLOTHES'));
    await tester.pumpAndSettle();

    expect(find.byType(ClothesPage), findsOneWidget);
    expect(find.text('denim pants (black)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
    store.dispose();
  });
}
