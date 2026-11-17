import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../models/catalog_garment.dart';
import '../../fitting_room/fitting_catalog.dart';
import 'catalog_garment_image.dart';

class CatalogGarmentGrid extends StatelessWidget {
  const CatalogGarmentGrid({
    super.key,
    required this.items,
    required this.imageUrl,
  });
  final List<CatalogGarment> items;
  final String? Function(String) imageUrl;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 300
          ? 1
          : constraints.maxWidth < 700
          ? 2
          : 3;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: MediaQuery.textScalerOf(context).scale(1) > 1.4
              ? .62
              : .82,
          mainAxisSpacing: 24,
          crossAxisSpacing: constraints.maxWidth >= 700 ? 48 : 18,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final url = imageUrl(item.thumbnailUrl);
          final fitting = FittingScope.maybeOf(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CatalogGarmentImage(url: url, name: item.name),
                    ),
                    if (fitting != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: IconButton.filledTonal(
                          tooltip: fitting.contains(item.id)
                              ? '${item.name} 담기 취소'
                              : '${item.name} 피팅룸에 담기',
                          onPressed: () => fitting.toggle(item),
                          icon: Icon(
                            fitting.contains(item.id) ? Icons.check : Icons.add,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  color: OseePalette.primary900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: faded, fontSize: 12),
              ),
            ],
          );
        },
      );
    },
  );
}
