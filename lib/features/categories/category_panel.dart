import 'dart:async';

import 'package:flutter/material.dart';

import 'category_catalog.dart';
import 'catalog_category.dart';
import 'category_labels.dart';
import '../clothes/widgets/category_pills.dart';

class CategoryPanel extends StatefulWidget {
  const CategoryPanel({
    super.key,
    required this.catalog,
    required this.selected,
    required this.subcategory,
    required this.onSelect,
    required this.onLogin,
    this.menu = false,
  });
  final CategoryCatalog catalog;
  final String selected;
  final String? subcategory;
  final void Function(String, [String?]) onSelect;
  final VoidCallback onLogin;
  final bool menu;

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

  ButtonStyle get _menuButtonStyle => TextButton.styleFrom(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(vertical: 4),
    minimumSize: const Size(0, 32),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  TextStyle _headingStyle(bool selected) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    color: selected ? const Color(0xff141414) : const Color(0xff43474f),
    fontWeight: FontWeight.w700,
  );

  Widget _menuItem(CatalogCategory root, CatalogCategory child) => TextButton(
    style: _menuButtonStyle,
    onPressed: () => widget.onSelect(root.code, child.code),
    child: Text(
      child.name,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: const Color(0xff8a9099),
        fontWeight: widget.subcategory == child.code
            ? FontWeight.w700
            : FontWeight.w400,
      ),
    ),
  );

  Widget _menuGroup(CatalogCategory root, double columnWidth, double gap) {
    final items = root.descendants.toList();
    final split = root.code == 'OUTERWEAR' && items.length > 1;
    final midpoint = (items.length + 1) ~/ 2;
    Widget column(Iterable<CatalogCategory> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final child in children) _menuItem(root, child)],
    );
    return SizedBox(
      width: split ? columnWidth * 2 + gap : columnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton(
            style: _menuButtonStyle,
            onPressed: () => widget.onSelect(root.code),
            child: Text(
              categoryLabel(root.code, root.name),
              style: _headingStyle(widget.selected == root.code),
            ),
          ),
          if (split)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column(items.take(midpoint))),
                SizedBox(width: gap),
                Expanded(child: column(items.skip(midpoint))),
              ],
            )
          else
            column(items),
        ],
      ),
    );
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
      if (widget.menu) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const allWidth = 72.0;
            const gap = 20.0;
            const columnGap = 16.0;
            final splitOuter = catalog.categories.any(
              (root) => root.code == 'OUTERWEAR' && root.descendants.length > 1,
            );
            final units = catalog.categories.length + (splitOuter ? 1 : 0);
            final columnWidth =
                ((constraints.maxWidth -
                            allWidth -
                            gap * catalog.categories.length -
                            (splitOuter ? columnGap : 0)) /
                        units)
                    .clamp(140.0, 200.0)
                    .toDouble();
            return Wrap(
              spacing: gap,
              runSpacing: 20,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                SizedBox(
                  width: allWidth,
                  child: TextButton(
                    style: _menuButtonStyle,
                    onPressed: () => widget.onSelect('all'),
                    child: Text(
                      'All',
                      style: _headingStyle(widget.selected == 'all'),
                    ),
                  ),
                ),
                for (final root in catalog.categories)
                  _menuGroup(root, columnWidth, columnGap),
              ],
            );
          },
        );
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
