import 'package:flutter/material.dart';

import '../../../core/providers/osee_store.dart';
import '../../../core/theme/osee_theme.dart';
import '../../categories/category_catalog.dart';
import '../../categories/category_panel.dart';
import '../widgets/garment_grid.dart';

class ClothesPage extends StatelessWidget {
  const ClothesPage({
    super.key,
    required this.store,
    required this.category,
    required this.subcategory,
    required this.filter,
    required this.categories,
    required this.onLogin,
  });
  final OseeStore store;
  final String category;
  final String? subcategory;
  final void Function(String, [String?]) filter;
  final CategoryCatalog categories;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    return ListenableBuilder(
      listenable: categories,
      builder: (context, _) {
        final root = categories.categories
            .where((c) => c.code == category)
            .firstOrNull;
        final child = root?.descendants
            .where((c) => c.code == subcategory)
            .firstOrNull;
        return ListView(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 20, 20, wide ? 32 : 20, 60),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      root == null ? '전체 의류' : root.name,
                      style: TextStyle(
                        fontSize: wide ? 40 : 30,
                        fontWeight: FontWeight.w500,
                        color: ink,
                      ),
                    ),
                    if (child != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          child.name,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!wide)
                      CategoryPanel(
                        catalog: categories,
                        selected: category,
                        subcategory: subcategory,
                        onSelect: filter,
                        onLogin: onLogin,
                      ),
                    const SizedBox(height: 28),
                    if (root != null)
                      const Text(
                        '선택한 카테고리의 상품은 준비 중입니다.',
                        style: TextStyle(color: faded),
                      )
                    else ...[
                      const Text(
                        '샘플 의류',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '상품 목록은 준비 중이며, 아래는 체험용 샘플입니다.',
                        style: TextStyle(color: faded),
                      ),
                      const SizedBox(height: 16),
                      if (store.catalog.isEmpty)
                        const Text(
                          '표시할 의류가 없습니다.',
                          style: TextStyle(color: faded),
                        )
                      else
                        GarmentGrid(items: store.catalog, store: store),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
