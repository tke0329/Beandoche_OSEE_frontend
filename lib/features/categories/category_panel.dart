import 'dart:async';

import 'package:flutter/material.dart';

import 'category_catalog.dart';
import '../clothes/widgets/category_pills.dart';

class CategoryPanel extends StatefulWidget {
  const CategoryPanel({
    super.key,
    required this.catalog,
    required this.selected,
    required this.subcategory,
    required this.onSelect,
    required this.onLogin,
  });
  final CategoryCatalog catalog;
  final String selected;
  final String? subcategory;
  final void Function(String, [String?]) onSelect;
  final VoidCallback onLogin;

  @override
  State<CategoryPanel> createState() => _CategoryPanelState();
}

class _CategoryPanelState extends State<CategoryPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.catalog.load());
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.catalog,
    builder: (context, _) {
      final catalog = widget.catalog;
      if (catalog.needsLogin) {
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            const Text('로그인 후 카테고리를 확인할 수 있습니다.'),
            TextButton(onPressed: widget.onLogin, child: const Text('로그인')),
          ],
        );
      }
      if (catalog.loading) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('카테고리를 불러오는 중입니다.'),
            ],
          ),
        );
      }
      if (catalog.error != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(catalog.error!, semanticsLabel: catalog.error),
            TextButton(onPressed: catalog.retry, child: const Text('다시 시도')),
          ],
        );
      }
      if (catalog.categories.isEmpty) {
        return const Text('표시할 카테고리가 없습니다.');
      }
      final selected = catalog.categories
          .where((c) => c.code == widget.selected)
          .firstOrNull;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryPills(
            categories: catalog.categories,
            selected: widget.selected,
            onSelect: (code) => widget.onSelect(code),
          ),
          if (selected != null && selected.children.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('전체 보기'),
                  selected: widget.subcategory == null,
                  onSelected: (_) => widget.onSelect(selected.code),
                ),
                for (final child in selected.descendants)
                  ChoiceChip(
                    label: Text(child.name),
                    selected: widget.subcategory == child.code,
                    onSelected: (_) =>
                        widget.onSelect(selected.code, child.code),
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );
}
