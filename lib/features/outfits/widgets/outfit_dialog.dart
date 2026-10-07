import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/features/outfits/models/outfit.dart';

import 'package:flutter/material.dart';

Future<void> outfitDialog(
  BuildContext context,
  OseeStore store, {
  Outfit? editing,
}) async {
  final controller = TextEditingController(
    text: editing?.name ?? '프리셋 ${store.outfits.length + 1}',
  );
  final ids = editing == null ? [...store.fittingIds] : [...editing.items];
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, refresh) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 25, 32, 38),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLength: 20,
                          onChanged: (_) => refresh(() {}),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 15, color: faded),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: faded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (ids.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 35),
                      child: Text('저장할 의류가 없습니다.'),
                    )
                  else
                    Wrap(
                      spacing: 18,
                      runSpacing: 15,
                      children: [
                        for (final id in ids)
                          SizedBox(
                            width: 110,
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        color: OseePalette.secondary50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(5),
                                      child: Image.asset(
                                        store.item(id)!.image,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: InkWell(
                                        onTap: () =>
                                            refresh(() => ids.remove(id)),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: background,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: line),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'size ${editing?.settings[id]?.size ?? store.settings[id]!.size}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 49,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        side: const BorderSide(color: OseePalette.primary200),
                      ),
                      onPressed: ids.isEmpty || controller.text.trim().isEmpty
                          ? null
                          : () {
                              if (editing == null) {
                                store.saveOutfit(controller.text.trim(), ids);
                              } else {
                                store.updateOutfit(
                                  editing.id,
                                  controller.text.trim(),
                                  ids,
                                );
                              }
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('착장을 저장했습니다')),
                              );
                            },
                      child: const Text(
                        '저장',
                        style: TextStyle(fontSize: 15, color: ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  controller.dispose();
}
