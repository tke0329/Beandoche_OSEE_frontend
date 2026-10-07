import 'package:beandoche_osee_frontend/core/utils/categories.dart';

import 'package:flutter/material.dart';

class CategoryPills extends StatelessWidget {
  const CategoryPills({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final category in sections.keys)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category == 'all'
                    ? 'All'
                    : '${category[0].toUpperCase()}${category.substring(1)}',
              ),
              selected: category == selected,
              onSelected: (_) => onSelect(category),
            ),
          ),
      ],
    ),
  );
}
