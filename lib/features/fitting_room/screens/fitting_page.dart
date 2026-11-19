import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../../../core/widgets/avatar_viewer.dart';
import '../../clothes/widgets/catalog_garment_image.dart';
import '../fitting_catalog.dart';
import '../widgets/garment_controls.dart';

class FittingPage extends StatefulWidget {
  const FittingPage({super.key, required this.catalog, required this.open});
  final FittingCatalog catalog;
  final ValueChanged<int> open;
  @override
  State<FittingPage> createState() => _FittingPageState();
}

class _FittingPageState extends State<FittingPage> {
  AvatarModel _model = AvatarModel.female;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.catalog.loadActive());
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.catalog,
    builder: (context, _) {
      final catalog = widget.catalog;
      final wide = MediaQuery.sizeOf(context).width >= 1050;
      final stage = _AvatarStage(
        height: wide ? 640 : 440,
        model: _model,
        onModel: (model) => setState(() => _model = model),
      );

      if (catalog.items.isEmpty) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
          child: Column(
            children: [
              stage,
              const SizedBox(height: 20),
              const Text('담은 의류가 없습니다.'),
              TextButton(
                onPressed: () => widget.open(1),
                child: const Text('CLOTHES에서 의류 담기'),
              ),
            ],
          ),
        );
      }

      final thumbs = _GarmentRail(catalog: catalog, vertical: wide);
      final panel = catalog.loading
          ? const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: CircularProgressIndicator(semanticsLabel: '상품 상세 조회 중'),
              ),
            )
          : catalog.error != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catalog.error!),
                TextButton(
                  onPressed: catalog.retry,
                  child: const Text('상품 다시 시도'),
                ),
              ],
            )
          : FittingPanel(catalog: catalog);

      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 48 : 20,
                40,
                wide ? 48 : 20,
                60,
              ),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 72),
                          child: SizedBox(width: 128, child: thumbs),
                        ),
                        const SizedBox(width: 48),
                        Expanded(child: stage),
                        const SizedBox(width: 64),
                        SizedBox(
                          width: 560,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: panel,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 140, child: thumbs),
                        const SizedBox(height: 16),
                        stage,
                        const SizedBox(height: 24),
                        panel,
                      ],
                    ),
            ),
          ),
        ),
      );
    },
  );
}

/// The 3D avatar on a soft spotlight column.
class _AvatarStage extends StatelessWidget {
  const _AvatarStage({
    required this.height,
    required this.model,
    required this.onModel,
  });
  final double height;
  final AvatarModel model;
  final ValueChanged<AvatarModel> onModel;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SegmentedButton<AvatarModel>(
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13)),
        ),
        segments: [
          for (final m in AvatarModel.values)
            ButtonSegment(value: m, label: Text(m.label)),
        ],
        selected: {model},
        onSelectionChanged: (selection) => onModel(selection.first),
      ),
      SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              bottom: height * 0.12,
              child: Container(
                width: height * 0.62,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00ffffff), Colors.white, Colors.white],
                    stops: [0, .35, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AvatarViewer(height: height, model: model),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Garments in the fitting room: a vertical rail on wide screens, horizontal otherwise.
class _GarmentRail extends StatelessWidget {
  const _GarmentRail({required this.catalog, required this.vertical});
  final FittingCatalog catalog;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (final item in catalog.items)
        _GarmentTile(
          name: item.name,
          imageUrl: catalog.imageUrl(item.thumbnailUrl),
          selected: catalog.activeId == item.id,
          onSelect: () => catalog.select(item.id),
          onRemove: () => catalog.remove(item.id),
        ),
    ];
    return vertical
        ? Column(
            children: [
              for (final tile in tiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: tile,
                ),
            ],
          )
        : ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(top: 8, right: 8),
            children: [
              for (final tile in tiles)
                Padding(padding: const EdgeInsets.only(right: 16), child: tile),
            ],
          );
  }
}

class _GarmentTile extends StatelessWidget {
  const _GarmentTile({
    required this.name,
    required this.imageUrl,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
  });
  final String name;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 124,
    height: 124,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            selected: selected,
            label: '$name 선택',
            child: Material(
              color: imageBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: selected ? OseePalette.primary300 : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onSelect,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Tooltip(
                    message: name,
                    child: CatalogGarmentImage(url: imageUrl, name: name),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Tooltip(
            message: '$name 제거',
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(side: BorderSide(color: line)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox.square(
                  dimension: 20,
                  child: Icon(Icons.close, size: 12, color: faded),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
