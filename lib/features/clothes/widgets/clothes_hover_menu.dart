import 'package:flutter/material.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';

import 'package:beandoche_osee_frontend/core/utils/categories.dart';

class ClothesHoverMenu extends StatelessWidget {
  const ClothesHoverMenu({
    super.key,
    required this.onSelect,
    required this.onExit,
  });
  final void Function(String, [String?]) onSelect;
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onExit: (_) => onExit(),
    child: Container(
      height: 152,
      color: OseePalette.secondary50,
      child: Padding(
        padding: const EdgeInsets.only(left: 310, top: 17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in sections.entries.where(
              (entry) => entry.key != 'accessory',
            )) ...[
              SizedBox(
                width: entry.key == 'outerwear' ? 150 : 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => onSelect(entry.key),
                      child: Text(
                        entry.key == 'all'
                            ? 'All'
                            : '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: OseePalette.tertiary700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final sub in entry.value.take(
                      entry.key == 'top' ? 4 : entry.value.length,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: InkWell(
                          onTap: () => onSelect(entry.key, sub),
                          child: Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 14,
                              color: OseePalette.tertiary500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
