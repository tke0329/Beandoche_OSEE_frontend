import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/features/clothes/models/garment.dart';
import 'package:beandoche_osee_frontend/features/outfits/models/outfit.dart';

import 'package:flutter/material.dart';

class OutfitCard extends StatelessWidget {
  const OutfitCard({
    super.key,
    required this.outfit,
    required this.store,
    required this.onLoad,
    required this.onEdit,
  });
  final Outfit outfit;
  final OseeStore store;
  final VoidCallback onLoad;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final garments = outfit.items.map(store.item).whereType<Garment>().toList();
    final uppers = garments
        .where((item) => item.category == 'top' || item.category == 'outerwear')
        .toList();
    final lowers = garments.where((item) => item.category == 'bottom').toList();
    final accents = garments
        .where(
          (item) => item.category == 'accessory' || item.category == 'shoes',
        )
        .toList();
    Widget picture(Garment item) => ColorFiltered(
      colorFilter: const ColorFilter.mode(
        OseePalette.secondary50,
        BlendMode.multiply,
      ),
      child: Image.asset(item.image, fit: BoxFit.contain),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return Container(
          decoration: BoxDecoration(
            color: OseePalette.secondary50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: OseePalette.shadowSoft,
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                for (var i = 0; i < lowers.length; i++)
                  Positioned(
                    left:
                        w *
                            (uppers.length > 1
                                ? .27
                                : accents.isNotEmpty
                                ? .43
                                : .25) +
                        i * 12,
                    top: h * (uppers.isEmpty ? .20 : .50),
                    width: w * .48,
                    height: h * .43,
                    child: picture(lowers[i]),
                  ),
                for (var i = 0; i < uppers.length; i++)
                  Positioned(
                    left:
                        w *
                        (uppers.length > 1
                            ? (i == 0 ? .08 : .48)
                            : accents.isNotEmpty
                            ? .07
                            : .22),
                    top: h * (uppers.length > 1 ? (i == 0 ? .14 : .22) : .09),
                    width: w * (uppers.length > 1 ? .44 : .56),
                    height: h * .50,
                    child: picture(uppers[i]),
                  ),
                for (var i = 0; i < accents.length; i++)
                  Positioned(
                    left: w * (.56 - i * .28),
                    top: h * .09,
                    width: w * .35,
                    height: h * .29,
                    child: picture(accents[i]),
                  ),
                Positioned(
                  left: 23,
                  top: 21,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 95),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      outfit.name,
                      style: const TextStyle(
                        color: OseePalette.primary50,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 15,
                  top: 18,
                  child: InkWell(
                    onTap: onLoad,
                    child: Container(
                      width: 51,
                      height: 51,
                      decoration: BoxDecoration(
                        color: OseePalette.primary100,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: OseePalette.shadowSoft,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.checkroom_outlined,
                        size: 28,
                        color: ink,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 13,
                  child: IconButton(
                    tooltip: '착장 수정',
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.tune,
                      color: OseePalette.tertiary300,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
