import 'package:flutter_test/flutter_test.dart';
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
    await tester.pumpWidget(OseeApp(initialStore: store));
    await tester.pumpAndSettle();

    expect(find.text('Before you buy,'), findsOneWidget);
    await tester.tap(find.text('CLOTHES'));
    await tester.pumpAndSettle();

    expect(find.byType(ClothesPage), findsOneWidget);
    expect(find.text('denim pants (black)'), findsOneWidget);
  });
}
