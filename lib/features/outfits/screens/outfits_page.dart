import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/features/outfits/widgets/outfit_card.dart';
import 'package:beandoche_osee_frontend/features/outfits/widgets/outfit_dialog.dart';

import 'package:flutter/material.dart';

class OutfitsPage extends StatefulWidget {
  const OutfitsPage({super.key, required this.store, required this.open});
  final OseeStore store;
  final ValueChanged<int> open;
  @override
  State<OutfitsPage> createState() => _OutfitsPageState();
}

class _OutfitsPageState extends State<OutfitsPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1050;
    final outfits = widget.store.outfits
        .where(
          (outfit) =>
              outfit.name.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
    return ListView(
      padding: EdgeInsets.fromLTRB(
        wide ? 32 : 20,
        wide ? 44 : 20,
        wide ? 32 : 20,
        70,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1184),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!wide) ...[
                  const Text(
                    'OUTFITS',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: wide ? 366 : double.infinity,
                    height: 50,
                    child: TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        suffixIcon: const Icon(
                          Icons.search,
                          color: OseePalette.tertiary200,
                          size: 27,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                            color: OseePalette.tertiary100,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                            color: OseePalette.tertiary100,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: wide ? 48 : 25),
                if (outfits.isEmpty)
                  Text(
                    query.isEmpty ? '저장한 착장이 없습니다.' : '검색 결과가 없습니다.',
                    style: const TextStyle(color: faded),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: outfits.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: wide
                          ? 3
                          : width >= 650
                          ? 2
                          : 1,
                      childAspectRatio: .78,
                      mainAxisSpacing: 35,
                      crossAxisSpacing: wide ? 40 : 20,
                    ),
                    itemBuilder: (context, index) {
                      final outfit = outfits[index];
                      return OutfitCard(
                        outfit: outfit,
                        store: widget.store,
                        onLoad: () {
                          widget.store.loadOutfit(outfit);
                          widget.open(2);
                        },
                        onEdit: () => outfitDialog(
                          context,
                          widget.store,
                          editing: outfit,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
