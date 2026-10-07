import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';

import 'package:flutter/material.dart';

class OseeHeader extends StatelessWidget {
  const OseeHeader({
    super.key,
    required this.activePage,
    required this.wide,
    required this.onNavigate,
    required this.onClothesHover,
    required this.onOtherHover,
  });
  final int activePage;
  final bool wide;
  final ValueChanged<int> onNavigate;
  final VoidCallback onClothesHover;
  final VoidCallback onOtherHover;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: wide ? 50 : 20),
        child: Row(
          children: [
            SizedBox(
              width: wide ? 260 : null,
              child: InkWell(
                onTap: () => onNavigate(0),
                child: const Text(
                  'OSEE',
                  style: TextStyle(
                    color: ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.8,
                  ),
                ),
              ),
            ),
            if (wide) ...[
              for (var index = 1; index <= 5; index++) ...[
                if (index > 1) const SizedBox(width: 49),
                MouseRegion(
                  onEnter: (_) =>
                      index == 1 ? onClothesHover() : onOtherHover(),
                  child: InkWell(
                    onTap: index == 5 ? null : () => onNavigate(index),
                    child: Text(
                      const [
                        'HOME',
                        'CLOTHES',
                        'FITTING ROOM',
                        'WARDROBE',
                        'OUTFITS',
                        'FEED',
                      ][index],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: activePage == index
                            ? ink
                            : OseePalette.tertiary200,
                      ),
                    ),
                  ),
                ),
              ],
            ],
            const Spacer(),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: OseePalette.primary100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: OseePalette.primary700,
                size: 27,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
