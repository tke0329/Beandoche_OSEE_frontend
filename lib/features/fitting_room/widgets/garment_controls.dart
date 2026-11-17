import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../../clothes/models/garment_options.dart';
import '../fitting_catalog.dart';

const _panelFill = Color(0xffeef2f8);
const _tabTrack = OseePalette.primary100;

/// Right-hand panel of the fitting room: garment name, then a Style tab
/// (color / size / details) and a Personalization tab (per-measurement fit).
class FittingPanel extends StatefulWidget {
  const FittingPanel({super.key, required this.catalog});
  final FittingCatalog catalog;

  @override
  State<FittingPanel> createState() => _FittingPanelState();
}

class _FittingPanelState extends State<FittingPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final detail = catalog.detail;
    if (detail == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                detail.garment.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.bookmark, size: 22, color: ink),
          ],
        ),
        const SizedBox(height: 24),
        _Tabs(
          labels: const ['Style', 'Personalization'],
          selected: _tab,
          onSelect: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 40),
        if (_tab == 0)
          _StyleTab(catalog: catalog, options: detail.options)
        else
          _FitTab(catalog: catalog),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    decoration: BoxDecoration(
      color: _tabTrack,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              selected: i == selected,
              button: true,
              child: Material(
                color: i == selected ? _panelFill : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect(i),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: i == selected ? ink : OseePalette.secondary300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.minHeight = 0});
  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: minHeight),
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
    decoration: BoxDecoration(
      color: _panelFill,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: OseePalette.primary100),
    ),
    child: child,
  );
}

// ---------------------------------------------------------------- Style

class _StyleTab extends StatelessWidget {
  const _StyleTab({required this.catalog, required this.options});
  final FittingCatalog catalog;
  final GarmentOptions options;

  @override
  Widget build(BuildContext context) {
    final selection = catalog.selection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          minHeight: 260,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              if (options.variants.isEmpty)
                const Text('선택 가능한 색상이 없습니다.', style: TextStyle(color: faded))
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in options.variants)
                      _Swatch(
                        name: color.name,
                        hex: color.hex,
                        selected: catalog.selectedVariantId == color.id,
                        onTap: () => catalog.chooseVariant(color.id),
                      ),
                  ],
                ),
              const SizedBox(height: 32),
              _SizeRow(catalog: catalog),
              const SizedBox(height: 40),
            ],
          ),
        ),
        if (catalog.selectionError != null) ...[
          const SizedBox(height: 12),
          Text(catalog.selectionError!),
          TextButton(
            onPressed: catalog.retrySelection,
            child: const Text('옵션 다시 시도'),
          ),
        ],
        const SizedBox(height: 28),
        _Section(
          title: '세부 정보',
          children: [
            Text(catalog.detail!.description),
            const SizedBox(height: 12),
            const Text(
              '소재 및 혼용률',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (options.materialStatus == 'UNKNOWN')
              const Text('소재·혼용률 미확인', style: TextStyle(color: faded)),
            for (final material in options.materials)
              Text('${material.name} ${formatNumber(material.percentage)}%'),
          ],
        ),
        _Section(
          title: '사이즈 정보',
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
              if (selection.measurements.isEmpty) const Text('등록된 실측이 없습니다.'),
              for (final measurement in selection.measurements) ...[
                const SizedBox(height: 12),
                Text(
                  '${measurement.name} · ${measurement.displayValue}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_basisLabel(measurement.basis)} · 출처: ${_sourceLabel(measurement.source)} · '
                  '측정일: ${measurement.measuredAt.toLocal().toIso8601String().split('T').first}',
                  style: const TextStyle(color: faded, fontSize: 12),
                ),
              ],
            ],
            if (options.rules.isEmpty) const Text('카테고리 측정 항목이 설정되지 않았습니다.'),
          ],
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: OseePalette.secondary600),
        ),
        tilePadding: EdgeInsets.zero,
        minTileHeight: 88,
        iconColor: faded,
        collapsedIconColor: faded,
        childrenPadding: const EdgeInsets.only(bottom: 20),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.hex,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String? hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = hex == null
        ? OseePalette.secondary100
        : Color(int.parse('ff${hex!.substring(1)}', radix: 16));
    return Tooltip(
      message: name,
      child: Semantics(
        button: true,
        selected: selected,
        label: '색상 $name',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: selected ? OseePalette.secondary600 : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: OseePalette.secondary200, width: .5),
              ),
              child: hex == null
                  ? Center(
                      child: Text(
                        name.characters.first,
                        style: const TextStyle(fontSize: 11, color: faded),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({required this.catalog, this.trailing});
  final FittingCatalog catalog;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final variant = catalog.selectedVariant;
    return Row(
      children: [
        Expanded(
          child: variant == null || variant.sizes.isEmpty
              ? const Text('판매 사이즈 정보가 없습니다.', style: TextStyle(color: faded))
              : Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final size in variant.sizes)
                      _SizeChip(
                        label: size.label,
                        available: size.available,
                        selected: catalog.selectedSizeId == size.id,
                        onTap: () => catalog.chooseSize(size.id),
                      ),
                  ],
                ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.available,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool available;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: available ? '사이즈 $label' : '$label 선택 불가',
    child: Semantics(
      button: true,
      selected: selected,
      enabled: available,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(
            color: selected ? ink : OseePalette.secondary100,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: available ? onTap : null,
          child: SizedBox(
            width: 38,
            height: 26,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: available ? ink : OseePalette.secondary200,
                  decoration: available ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- Personalization

class _FitTab extends StatelessWidget {
  const _FitTab({required this.catalog});
  final FittingCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final selection = catalog.selection;
    final rules = catalog.detail!.options.rules;
    final measurements = [
      for (final m in selection?.measurements ?? const <SizeMeasurement>[])
        if (m.unit == 'mm') m,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SizeRow(
                catalog: catalog,
                trailing: TextButton.icon(
                  onPressed: measurements.isEmpty ? null : catalog.resetFit,
                  style: TextButton.styleFrom(
                    foregroundColor: OseePalette.secondary600,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('기본값'),
                ),
              ),
              const SizedBox(height: 12),
              if (catalog.selecting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LinearProgressIndicator(
                    semanticsLabel: '선택한 사이즈 정보 조회 중',
                  ),
                )
              else if (catalog.selectedSizeId == null)
                const _Note('사이즈를 선택하면 실측을 조정할 수 있습니다.')
              else if (catalog.selectionError != null)
                _Note(catalog.selectionError!)
              else if (measurements.isEmpty)
                const _Note('조정할 수 있는 실측이 없습니다.')
              else
                for (final m in measurements)
                  _MeasureSlider(
                    measurement: m,
                    rule: rules
                        .where((r) => r.id == m.definitionId)
                        .firstOrNull,
                    value: catalog.fitValue(m),
                    onChanged: (mm) => catalog.adjustFit(m.definitionId, mm),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: OseePalette.secondary600,
              disabledBackgroundColor: OseePalette.secondary200,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: catalog.fitDirty
                ? () {
                    catalog.saveFit();
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('내 핏 설정을 저장했습니다.')),
                    );
                  }
                : null,
            child: const Text('저장'),
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Text(text, style: const TextStyle(color: faded)),
  );
}

class _MeasureSlider extends StatelessWidget {
  const _MeasureSlider({
    required this.measurement,
    required this.rule,
    required this.value,
    required this.onChanged,
  });
  final SizeMeasurement measurement;
  final MeasurementRule? rule;
  final num value;
  final ValueChanged<num> onChanged;

  @override
  Widget build(BuildContext context) {
    final base = measurement.valueMm.toDouble();
    var min = rule?.minMm?.toDouble() ?? base * .75;
    var max = rule?.maxMm?.toDouble() ?? base * 1.25;
    if (min >= base || max <= base) {
      min = base * .75;
      max = base * 1.25;
    }
    const step = 5.0; // 0.5 cm
    min = (min / step).floorToDouble() * step;
    max = (max / step).ceilToDouble() * step;
    final current = value.toDouble().clamp(min, max);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: OseePalette.secondary100, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  measurement.name,
                  style: const TextStyle(
                    fontSize: 13,
                    color: OseePalette.secondary700,
                  ),
                ),
                if (rule?.description case final description?
                    when description.isNotEmpty)
                  Tooltip(
                    message: description,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text(
                        '?',
                        style: TextStyle(fontSize: 9, color: faded),
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  formatNumber((current / 10 * 2).round() / 2),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('cm', style: TextStyle(fontSize: 12, color: faded)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.5,
                activeTrackColor: OseePalette.secondary200,
                inactiveTrackColor: OseePalette.secondary200,
                thumbColor: OseePalette.secondary400,
                overlayColor: OseePalette.secondary400.withValues(alpha: .12),
                thumbShape: const _SquareThumb(),
                showValueIndicator: ShowValueIndicator.never,
                padding: EdgeInsets.zero,
              ),
              child: SizedBox(
                height: 36,
                child: Slider(
                  value: current,
                  min: min,
                  max: max,
                  divisions: ((max - min) / step).round(),
                  semanticFormatterCallback: (v) =>
                      '${measurement.name} ${formatNumber(v / 10)} cm',
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareThumb extends SliderComponentShape {
  const _SquareThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(12, 14);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 12, height: 14),
        const Radius.circular(3),
      ),
      Paint()..color = sliderTheme.thumbColor ?? OseePalette.secondary400,
    );
  }
}
