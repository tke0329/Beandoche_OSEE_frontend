import 'package:flutter/material.dart';

import '../../categories/category_catalog.dart';
import '../../categories/category_labels.dart';
import '../../categories/category_panel.dart';
import '../garment_catalog.dart';
import '../widgets/garment_list.dart';

class ClothesPage extends StatelessWidget {
  const ClothesPage({
    super.key,
    required this.garments,
    required this.category,
    required this.subcategory,
    required this.filter,
    required this.categories,
    required this.onLogin,
  });
  final GarmentCatalog garments;
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
                constraints: const BoxConstraints.tightFor(width: 1064),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          root == null
                              ? 'All'
                              : categoryLabel(root.code, root.name),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: wide ? 38 : 30,
                            height: 1,
                            letterSpacing: wide ? -.38 : -.3,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff141414),
                          ),
                        ),
                        if (child != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '/ ${child.name}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                height: 1,
                                color: Color(0xff141414),
                              ),
                            ),
                          ),
                      ],
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
                    GarmentList(
                      catalog: garments,
                      categoryCode:
                          subcategory ?? (category == 'all' ? null : category),
                      onLogin: onLogin,
                    ),
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
