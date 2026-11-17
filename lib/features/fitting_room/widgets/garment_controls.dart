import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../../clothes/models/garment_options.dart';
import '../fitting_catalog.dart';

class GarmentControls extends StatelessWidget {
  const GarmentControls({super.key, required this.catalog});
  final FittingCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final detail = catalog.detail;
    if (detail == null) return const SizedBox.shrink();
    final options = detail.options;
    final variant = catalog.selectedVariant;
    final selection = catalog.selection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.garment.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: OseePalette.primary100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('COLOR'),
              const SizedBox(height: 12),
              if (options.variants.isEmpty)
                const Text('선택 가능한 색상이 없습니다.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final color in options.variants)
                      ChoiceChip(
                        label: Text(color.name),
                        selected: catalog.selectedVariantId == color.id,
                        avatar: color.hex == null
                            ? null
                            : CircleAvatar(
                                backgroundColor: Color(
                                  int.parse(
                                    'ff${color.hex!.substring(1)}',
                                    radix: 16,
                                  ),
                                ),
                              ),
                        onSelected: (_) => catalog.chooseVariant(color.id),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              const Text('SIZE'),
              const SizedBox(height: 12),
              if (variant == null || variant.sizes.isEmpty)
                const Text('판매 사이즈 정보가 없습니다.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final size in variant.sizes)
                      ChoiceChip(
                        label: Text(
                          size.available ? size.label : '${size.label} (선택 불가)',
                        ),
                        selected: catalog.selectedSizeId == size.id,
                        onSelected: size.available
                            ? (_) => catalog.chooseSize(size.id)
                            : null,
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (catalog.selecting)
          const LinearProgressIndicator(semanticsLabel: '선택한 사이즈 정보 조회 중'),
        if (catalog.selectionError != null) ...[
          Text(catalog.selectionError!),
          TextButton(
            onPressed: catalog.retrySelection,
            child: const Text('옵션 다시 시도'),
          ),
          TextButton(onPressed: catalog.retry, child: const Text('상품 정보 새로고침')),
        ],
        ExpansionTile(
          title: const Text('세부 정보'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.description),
                  const SizedBox(height: 12),
                  const Text('소재 및 혼용률'),
                  if (options.materialStatus == 'UNKNOWN')
                    const Text('소재·혼용률 미확인', style: TextStyle(color: faded)),
                  for (final material in options.materials)
                    Text(
                      '${material.name} ${formatNumber(material.percentage)}%',
                    ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        ExpansionTile(
          title: const Text('사이즈 정보'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catalog.selectedSizeId == null)
                    const Text('사이즈를 선택하면 실측을 확인할 수 있습니다.')
                  else if (selection != null) ...[
                    Text(switch (selection.validationStatus) {
                      'VALID' => '실측 검증 완료',
                      'INVALID' => '실측 검증 실패',
                      _ => '실측 검증 불가',
                    }, style: const TextStyle(fontWeight: FontWeight.w600)),
                    for (final issue in selection.issues)
                      Text(
                        '${_issueName(options.rules, issue.measurementCode)}${issue.message}',
                      ),
                    if (selection.measurements.isEmpty)
                      const Text('등록된 실측이 없습니다.'),
                    for (final measurement in selection.measurements) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${measurement.name} · ${measurement.displayValue}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _basisLabel(measurement.basis),
                        style: const TextStyle(color: faded),
                      ),
                      Text('출처: ${_sourceLabel(measurement.source)}'),
                      Text(
                        '측정일: ${measurement.measuredAt.toLocal().toIso8601String().split('T').first}',
                      ),
                      if (options.rules
                              .where(
                                (rule) => rule.id == measurement.definitionId,
                              )
                              .firstOrNull
                          case final rule?)
                        Text('측정 방법: ${rule.description}'),
                    ],
                  ],
                  if (options.rules.isEmpty)
                    const Text('카테고리 측정 항목이 설정되지 않았습니다.'),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),
        const Text('3D 모델 미제공', style: TextStyle(color: faded)),
        const Text(
          '실측 검증 상태와 3D 피팅 지원 여부는 별도입니다.',
          style: TextStyle(color: faded, fontSize: 12),
        ),
      ],
    );
  }

  String _issueName(List<MeasurementRule> rules, String? code) {
    final name = rules.where((rule) => rule.code == code).firstOrNull?.name;
    return name == null ? '' : '$name: ';
  }

  String _basisLabel(String basis) => switch (basis) {
    'FLAT_WIDTH' => '단면 너비',
    'CIRCUMFERENCE' => '둘레',
    'LENGTH' => '길이',
    'WEIGHT' => '무게',
    _ => basis,
  };
  String _sourceLabel(String source) => switch (source) {
    'BRAND_PROVIDED' => '브랜드 제공',
    'DIRECT_MEASUREMENT' => '직접 측정',
    'USER_PROVIDED' => '사용자 제공',
    'ESTIMATED' => '추정값',
    _ => source,
  };
}
