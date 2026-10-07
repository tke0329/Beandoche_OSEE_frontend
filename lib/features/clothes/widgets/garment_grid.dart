import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/features/clothes/models/garment.dart';

import 'package:flutter/material.dart';

class GarmentGrid extends StatelessWidget {
  const GarmentGrid({
    super.key,
    required this.items,
    required this.store,
    this.onSelect,
  });
  final List<Garment> items;
  final OseeStore store;
  final ValueChanged<Garment>? onSelect;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1050;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide
            ? 3
            : width >= 700
            ? 3
            : 2,
        childAspectRatio: wide ? .91 : .82,
        mainAxisSpacing: wide ? 30 : 24,
        crossAxisSpacing: wide ? 48 : 18,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final added = store.fittingIds.contains(item.id);
        return InkWell(
          onTap: onSelect == null ? null : () => onSelect!(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: imageBackground,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(item.image, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Tooltip(
                        message: added ? '피팅룸에서 빼기' : '피팅룸에 추가',
                        child: InkWell(
                          onTap: () => store.toggleFitting(item.id),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: added ? point : Colors.transparent,
                              border: Border.all(color: point, width: 1.7),
                            ),
                            child: Icon(
                              added ? Icons.check : Icons.add,
                              color: added ? OseePalette.primary50 : point,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: wide ? 16 : 12,
                  color: OseePalette.primary900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
