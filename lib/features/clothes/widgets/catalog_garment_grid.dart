import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../models/catalog_garment.dart';

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
          Widget fallback() => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported_outlined, color: faded),
                SizedBox(height: 6),
                Text('이미지 없음', style: TextStyle(color: faded, fontSize: 12)),
              ],
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: imageBackground,
                  child: url == null
                      ? fallback()
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          semanticLabel: '${item.name} 이미지',
                          errorBuilder: (context, error, stack) => fallback(),
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                        ),
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
