import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/core/widgets/avatar_stage.dart';
import 'package:beandoche_osee_frontend/features/fitting_room/widgets/garment_controls.dart';
import 'package:beandoche_osee_frontend/features/outfits/widgets/outfit_dialog.dart';

import 'package:flutter/material.dart';

class FittingPage extends StatefulWidget {
  const FittingPage({super.key, required this.store, required this.open});
  final OseeStore store;
  final ValueChanged<int> open;
  @override
  State<FittingPage> createState() => _FittingPageState();
}

class _FittingPageState extends State<FittingPage> {
  bool personalize = false;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final garment = store.item(store.activeId);
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    final thumbs = store.fittingIds.isEmpty
        ? TextButton(
            onPressed: () => widget.open(1),
            child: const Text('선택한 의류가 없습니다. CLOTHES에서 추가하세요.'),
          )
        : SizedBox(
            height: wide ? 620 : 116,
            child: ListView(
              scrollDirection: wide ? Axis.vertical : Axis.horizontal,
              children: [
                for (final id in store.fittingIds)
                  SizedBox(
                    width: 124,
                    height: wide ? 128 : 112,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 18),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: InkWell(
                              onTap: () => store.select(id),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: OseePalette.tertiary50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: id == store.activeId
                                        ? point
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Image.asset(
                                  store.item(id)!.image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () => store.toggleFitting(id),
                              child: Container(
                                width: 23,
                                height: 23,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: background,
                                  border: Border.all(
                                    color: OseePalette.secondary100,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: ink,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
    final controls = garment == null
        ? const Text('의류를 선택하면 설정을 변경할 수 있습니다.', style: TextStyle(color: faded))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      garment.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '저장 메뉴',
                    icon: const Icon(
                      Icons.bookmark_border,
                      color: OseePalette.primary700,
                      size: 27,
                    ),
                    onSelected: (value) {
                      if (value == 'wardrobe') {
                        store.toggleWardrobe(garment.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              store.wardrobe.contains(garment.id)
                                  ? '옷장에 저장했습니다'
                                  : '옷장에서 삭제했습니다',
                            ),
                          ),
                        );
                      } else {
                        outfitDialog(context, store);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'wardrobe', child: Text('내 옷장에 저장')),
                      PopupMenuItem(value: 'outfit', child: Text('착장 저장')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: OseePalette.primary100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    for (final entry in const [
                      (false, 'Style'),
                      (true, 'Personalization'),
                    ])
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => personalize = entry.$1),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: personalize == entry.$1
                                  ? OseePalette.primary100
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              entry.$2,
                              style: TextStyle(
                                fontSize: 16,
                                color: personalize == entry.$1
                                    ? ink
                                    : OseePalette.tertiary200,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              GarmentControls(
                item: garment,
                store: store,
                personalize: personalize,
              ),
            ],
          );
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1170),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 0 : 20,
              wide ? 42 : 20,
              wide ? 0 : 20,
              60,
            ),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 36),
                          child: thumbs,
                        ),
                      ),
                      const SizedBox(width: 35),
                      const Expanded(child: AvatarStage()),
                      const SizedBox(width: 35),
                      Transform.translate(
                        offset: const Offset(20, 0),
                        child: SizedBox(width: 534, child: controls),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      thumbs,
                      const AvatarStage(),
                      const SizedBox(height: 28),
                      controls,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
