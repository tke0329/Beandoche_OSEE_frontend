import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../../../core/widgets/avatar_stage.dart';
import '../../clothes/widgets/catalog_garment_image.dart';
import '../fitting_catalog.dart';
import '../widgets/garment_controls.dart';

class FittingPage extends StatefulWidget {
  const FittingPage({super.key, required this.catalog, required this.open});
  final FittingCatalog catalog;
  final ValueChanged<int> open;
  @override
  State<FittingPage> createState() => _FittingPageState();
}

class _FittingPageState extends State<FittingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.catalog.loadActive());
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.catalog,
    builder: (context, _) {
      final catalog = widget.catalog;
      if (catalog.items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('담은 의류가 없습니다.'),
              TextButton(
                onPressed: () => widget.open(1),
                child: const Text('CLOTHES에서 의류 담기'),
              ),
            ],
          ),
        );
      }
      final wide = MediaQuery.sizeOf(context).width >= 1050;
      final thumbs = SizedBox(
        height: wide ? 620 : 160,
        child: ListView(
          scrollDirection: wide ? Axis.vertical : Axis.horizontal,
          children: [
            for (final item in catalog.items)
              SizedBox(
                width: 124,
                height: 156,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Semantics(
                                selected: catalog.activeId == item.id,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(
                                      color: catalog.activeId == item.id
                                          ? point
                                          : line,
                                      width: 2,
                                    ),
                                  ),
                                  onPressed: () => catalog.select(item.id),
                                  child: Tooltip(
                                    message: '${item.name} 선택',
                                    child: SizedBox.expand(
                                      child: CatalogGarmentImage(
                                        url: catalog.imageUrl(
                                          item.thumbnailUrl,
                                        ),
                                        name: item.name,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton.filledTonal(
                                tooltip: '${item.name} 제거',
                                onPressed: () => catalog.remove(item.id),
                                icon: const Icon(Icons.close, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
      final controls = catalog.loading
          ? const Center(
              child: CircularProgressIndicator(semanticsLabel: '상품 상세 조회 중'),
            )
          : catalog.error != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catalog.error!),
                TextButton(
                  onPressed: catalog.retry,
                  child: const Text('상품 다시 시도'),
                ),
              ],
            )
          : GarmentControls(catalog: catalog);
      final stage = Column(
        children: [
          const Text(
            '아바타 예시 · 실제 착용 결과가 아닙니다.',
            style: TextStyle(color: faded),
          ),
          AvatarStage(height: wide ? 580 : 360),
          const Text('3D 의류 모델 미제공', style: TextStyle(color: faded)),
        ],
      );
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1170),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 60),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 124, child: thumbs),
                        const SizedBox(width: 24),
                        Expanded(child: stage),
                        const SizedBox(width: 24),
                        SizedBox(width: 410, child: controls),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thumbs,
                        stage,
                        const SizedBox(height: 24),
                        controls,
                      ],
                    ),
            ),
          ),
        ),
      );
    },
  );
}
