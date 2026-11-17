import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../garment_catalog.dart';
import 'catalog_garment_grid.dart';

class GarmentList extends StatefulWidget {
  const GarmentList({
    super.key,
    required this.catalog,
    required this.categoryCode,
    required this.onLogin,
  });
  final GarmentCatalog catalog;
  final String? categoryCode;
  final VoidCallback onLogin;

  @override
  State<GarmentList> createState() => _GarmentListState();
}

class _GarmentListState extends State<GarmentList> {
  @override
  void initState() {
    super.initState();
    _loadAfterBuild();
  }

  @override
  void didUpdateWidget(GarmentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalog != widget.catalog ||
        oldWidget.categoryCode != widget.categoryCode) {
      _loadAfterBuild();
    }
  }

  void _loadAfterBuild() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      unawaited(widget.catalog.load(categoryCode: widget.categoryCode));
    }
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.catalog,
    builder: (context, _) {
      final catalog = widget.catalog;
      if (catalog.needsLogin) {
        return Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('로그인 후 상품을 확인할 수 있습니다.'),
            TextButton(onPressed: widget.onLogin, child: const Text('로그인')),
          ],
        );
      }
      if (catalog.loading || catalog.categoryCode != widget.categoryCode) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('상품을 불러오는 중입니다.'),
              ],
            ),
          ),
        );
      }
      if (catalog.error != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(catalog.error!, style: const TextStyle(color: faded)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: catalog.retry,
                  child: const Text('상품 다시 시도'),
                ),
                if (catalog.page > 0)
                  TextButton(
                    onPressed: () => catalog.load(
                      categoryCode: widget.categoryCode,
                      page: catalog.page - 1,
                    ),
                    child: const Text('이전 페이지'),
                  ),
              ],
            ),
          ],
        );
      }
      final data = catalog.data;
      if (data == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 ${data.totalElements}개 · 최신 등록순',
            style: const TextStyle(color: faded),
          ),
          const SizedBox(height: 16),
          if (data.content.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                widget.categoryCode == null
                    ? '등록된 상품이 없습니다.'
                    : '선택한 카테고리에 등록된 상품이 없습니다.',
                style: const TextStyle(color: faded),
              ),
            )
          else
            CatalogGarmentGrid(items: data.content, imageUrl: catalog.imageUrl),
          if (data.totalPages > 1 || data.page > 0) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: data.page > 0
                      ? () => catalog.load(
                          categoryCode: widget.categoryCode,
                          page: data.page - 1,
                        )
                      : null,
                  child: const Text('이전 페이지'),
                ),
                Text('${data.page + 1} / ${data.totalPages} 페이지'),
                OutlinedButton(
                  onPressed: data.page + 1 < data.totalPages
                      ? () => catalog.load(
                          categoryCode: widget.categoryCode,
                          page: data.page + 1,
                        )
                      : null,
                  child: const Text('다음 페이지'),
                ),
              ],
            ),
          ],
        ],
      );
    },
  );
}
