import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/core/utils/categories.dart';
import 'package:beandoche_osee_frontend/core/widgets/avatar_stage.dart';
import 'package:beandoche_osee_frontend/features/clothes/models/garment.dart';

import 'package:flutter/material.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key, required this.store, required this.open});
  final OseeStore store;
  final ValueChanged<int> open;
  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  String category = 'all';
  Garment? selected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1050;
    final items = widget.store.wardrobe
        .map(widget.store.item)
        .whereType<Garment>()
        .where((item) => category == 'all' || item.category == category)
        .toList();
    final grid = Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!wide) ...[
              const Text(
                'WARDROBE',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final key in sections.keys.where(
                    (key) => key != 'accessory',
                  ))
                    Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: InkWell(
                        onTap: () => setState(() {
                          category = key;
                          selected = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: category == key
                                ? OseePalette.secondary900
                                : OseePalette.tertiary100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            key == 'all'
                                ? 'All'
                                : '${key[0].toUpperCase()}${key.substring(1)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: category == key
                                  ? OseePalette.primary50
                                  : OseePalette.tertiary700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            if (widget.store.wardrobe.isEmpty)
              TextButton(
                onPressed: () => widget.open(2),
                child: const Text('옷장이 비어 있습니다. 피팅룸에서 의류를 저장하세요.'),
              )
            else if (items.isEmpty)
              const Text(
                '이 카테고리에 저장한 의류가 없습니다.',
                style: TextStyle(color: faded),
              )
            else
              SizedBox(
                width: wide ? 910 : double.infinity,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wide
                        ? 3
                        : width >= 650
                        ? 3
                        : 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: wide ? 32 : 15,
                    mainAxisSpacing: 25,
                  ),
                  itemBuilder: (context, index) {
                    final garment = items[index];
                    return InkWell(
                      onTap: () => setState(() => selected = garment),
                      child: Container(
                        color: imageBackground,
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(garment.image, fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            wide ? 60 : 20,
            wide ? 20 : 20,
            wide ? 60 : 20,
            80,
          ),
          children: [grid],
        ),
        if (selected != null)
          Positioned(
            top: wide ? 49 : 20,
            right: wide ? 64 : 20,
            bottom: wide ? 22 : 20,
            width: wide ? 438 : width - 40,
            child: Container(
              decoration: BoxDecoration(
                color: background,
                border: Border.all(color: OseePalette.secondary100),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(
                    color: OseePalette.shadowSoft,
                    blurRadius: 5,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Transform.translate(
                      offset: const Offset(0, -15),
                      child: AvatarStage(
                        height: wide ? 520 : 400,
                        showPlatform: false,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 21,
                    top: 17,
                    child: IconButton(
                      onPressed: () => setState(() => selected = null),
                      icon: const Icon(
                        Icons.close,
                        color: OseePalette.tertiary200,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
