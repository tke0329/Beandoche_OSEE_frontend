import 'package:flutter/material.dart';

import '../../categories/catalog_category.dart';

class CategoryPills extends StatelessWidget {
  const CategoryPills({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<CatalogCategory> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: const Text('전체'),
        selected: !categories.any((c) => c.code == selected),
        onSelected: (_) => onSelect('all'),
      ),
      for (final category in categories)
        ChoiceChip(
          label: Text(category.name),
          selected: category.code == selected,
          onSelected: (_) => onSelect(category.code),
        ),
    ],
  );
}
