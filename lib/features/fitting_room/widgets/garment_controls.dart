import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/features/clothes/models/garment.dart';

import 'package:flutter/material.dart';

class GarmentControls extends StatelessWidget {
  const GarmentControls({
    super.key,
    required this.item,
    required this.store,
    required this.personalize,
  });
  final Garment item;
  final OseeStore store;
  final bool personalize;

  @override
  Widget build(BuildContext context) {
    final setting = store.settings[item.id]!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            personalize ? 38 : 50,
            personalize ? 24 : 42,
            personalize ? 38 : 36,
            personalize ? 30 : 49,
          ),
          decoration: BoxDecoration(
            color: OseePalette.primary100,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: OseePalette.shadowMedium,
                blurRadius: 3,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!personalize) ...[
                const Text(
                  'COLOR',
                  style: TextStyle(fontSize: 16, color: OseePalette.primary900),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final color in item.colors)
                      Tooltip(
                        message: color['name'] as String,
                        child: InkWell(
                          onTap: () =>
                              store.color(item.id, color['id'] as String),
                          child: Container(
                            width: 29,
                            height: 29,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(
                                int.parse(
                                  'ff${(color['hex'] as String).substring(1)}',
                                  radix: 16,
                                ),
                              ),
                              border: Border.all(
                                color: setting.colorId == color['id']
                                    ? point
                                    : Colors.transparent,
                              ),
                              boxShadow: setting.colorId == color['id']
                                  ? const [
                                      BoxShadow(
                                        color: OseePalette.shadowStrong,
                                        blurRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'SIZE',
                  style: TextStyle(fontSize: 16, color: OseePalette.primary900),
                ),
                const SizedBox(height: 9),
                _SizeButtons(item: item, store: store),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _SizeButtons(item: item, store: store),
                    ),
                    TextButton.icon(
                      onPressed: () => store.reset(item.id),
                      icon: const Icon(Icons.refresh, size: 17),
                      label: const Text('기본값'),
                      style: TextButton.styleFrom(foregroundColor: faded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final field in item.fields)
                  _MeasureRow(item: item, field: field, store: store),
              ],
            ],
          ),
        ),
        if (personalize) ...[
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: OseePalette.secondary600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('설정이 적용되었습니다'))),
              child: const Text('저장', style: TextStyle(fontSize: 16)),
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          ExpansionTile(
            minTileHeight: 72,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text(
              '세부 정보',
              style: TextStyle(fontSize: 16, color: OseePalette.primary900),
            ),
            children: [
              for (final detail in item.details)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(detail),
                  ),
                ),
            ],
          ),
          const Divider(height: 1, color: line),
          const SizedBox(height: 12),
          ExpansionTile(
            minTileHeight: 84,
            tilePadding: EdgeInsets.zero,
            title: const Text(
              '사이즈 정보',
              style: TextStyle(fontSize: 16, color: OseePalette.primary900),
            ),
            children: [
              for (final size in item.sizes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$size  ·  ${item.fields.map((field) => '${field['label']} ${item.measuresFor(size)[field['key']]}cm').join('  /  ')}',
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 1, color: line),
        ],
      ],
    );
  }
}

class _SizeButtons extends StatelessWidget {
  const _SizeButtons({required this.item, required this.store});
  final Garment item;
  final OseeStore store;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: [
      for (final size in item.sizes)
        InkWell(
          onTap: () => store.size(item.id, size),
          child: Container(
            width: 46,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OseePalette.primary50,
              border: Border.all(
                color: store.settings[item.id]!.size == size
                    ? point
                    : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              size,
              style: const TextStyle(
                fontSize: 13,
                color: OseePalette.primary900,
              ),
            ),
          ),
        ),
    ],
  );
}

class _MeasureRow extends StatelessWidget {
  const _MeasureRow({
    required this.item,
    required this.field,
    required this.store,
  });
  final Garment item;
  final Map<String, dynamic> field;
  final OseeStore store;
  @override
  Widget build(BuildContext context) {
    final value = store.settings[item.id]!.measures[field['key']]!;
    final min = (field['min'] as num).toDouble();
    final max = (field['max'] as num).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: OseePalette.secondary200, width: 2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  field['label'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
                InkWell(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(field['label'] as String),
                      content: Text(field['help'] as String),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.help_outline, size: 11),
                ),
                const Spacer(),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('cm', style: TextStyle(fontSize: 12, color: faded)),
              ],
            ),
            SizedBox(
              height: 17,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 1,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: OseePalette.secondary200,
                  inactiveTrackColor: OseePalette.secondary200,
                  thumbColor: OseePalette.primary200,
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: ((max - min) * 2).round(),
                  onChanged: (newValue) =>
                      store.measure(item.id, field['key'] as String, newValue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
