import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/core/utils/categories.dart';
import 'package:beandoche_osee_frontend/features/clothes/widgets/category_pills.dart';
import 'package:beandoche_osee_frontend/features/clothes/widgets/garment_grid.dart';

import 'package:flutter/material.dart';

class ClothesPage extends StatelessWidget {
  const ClothesPage({
    super.key,
    required this.store,
    required this.category,
    required this.subcategory,
    required this.filter,
  });
  final OseeStore store;
  final String category;
  final String? subcategory;
  final void Function(String, [String?]) filter;
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    final items = store.catalog
        .where(
          (item) =>
              (category == 'all' || item.category == category) &&
              (subcategory == null || item.sub == subcategory),
        )
        .toList();
    return ListView(
      padding: EdgeInsets.fromLTRB(
        wide ? 32 : 20,
        wide ? 12 : 20,
        wide ? 32 : 20,
        60,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: ink),
                    children: [
                      TextSpan(
                        text: category == 'all'
                            ? 'All'
                            : '${category[0].toUpperCase()}${category.substring(1)}',
                        style: TextStyle(
                          fontSize: wide ? 40 : 30,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subcategory != null)
                        TextSpan(
                          text: ' / $subcategory',
                          style: TextStyle(
                            fontSize: wide ? 22 : 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!wide) ...[
                  const SizedBox(height: 16),
                  CategoryPills(
                    selected: category,
                    onSelect: (value) => filter(value),
                  ),
                  if (sections[category]!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('전체'),
                            selected: subcategory == null,
                            onSelected: (_) => filter(category),
                          ),
                          for (final sub in sections[category]!)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(sub),
                                selected: subcategory == sub,
                                onSelected: (_) => filter(category, sub),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
                SizedBox(height: wide ? 20 : 24),
                if (items.isEmpty)
                  const Text(
                    '이 카테고리에는 아직 등록된 의류가 없습니다.',
                    style: TextStyle(color: faded),
                  )
                else
                  GarmentGrid(items: items, store: store),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
