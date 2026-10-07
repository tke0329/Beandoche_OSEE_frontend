import 'package:beandoche_osee_frontend/features/clothes/models/garment.dart';
import 'package:beandoche_osee_frontend/features/outfits/models/outfit.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OseeStore extends ChangeNotifier {
  final List<Garment> catalog = [];
  final List<String> fittingIds = ['vintage-tee', 'leather-pants'];
  String? activeId = 'vintage-tee';
  final Map<String, GarmentSetting> settings = {};
  final List<String> wardrobe = [];
  final List<Outfit> outfits = [];
  File? _saveFile;

  Garment? item(String? id) {
    for (final garment in catalog) {
      if (garment.id == id) return garment;
    }
    return null;
  }

  Future<void> initialize() async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/data/catalog.json'),
    ) as List;
    catalog.addAll(
      data.map((entry) => Garment((entry as Map).cast<String, dynamic>())),
    );
    for (final garment in catalog) {
      settings[garment.id] = GarmentSetting.initial(garment);
    }
    wardrobe.addAll(['sweat-navy', 'vintage-tee', 'denim-black']);
    outfits.addAll([
      _sample('sample-michelle', '미쉘룩', ['puffer-grey', 'denim-black']),
      _sample(
        'sample-arc',
        '아크룩',
        ['vintage-tee', 'cap-burgundy', 'jogger-grey'],
        {'vintage-tee': 'S', 'jogger-grey': '27'},
      ),
      _sample(
        'sample-yar',
        '야르룩',
        ['flower-zip', 'graphic-sweat', 'sweat-navy'],
        {'graphic-sweat': 'L', 'sweat-navy': '29'},
      ),
    ]);
    try {
      final directory = await getApplicationDocumentsDirectory();
      _saveFile = File('${directory.path}/osee_frontend_v1.json');
      if (await _saveFile!.exists()) {
        final saved =
            jsonDecode(await _saveFile!.readAsString()) as Map<String, dynamic>;
        wardrobe
          ..clear()
          ..addAll(
            (saved['wardrobe'] as List).cast<String>().where(
              (id) => item(id) != null,
            ),
          );
        outfits
          ..clear()
          ..addAll(
            (saved['outfits'] as List)
                .map(
                  (value) =>
                      Outfit.fromJson((value as Map).cast<String, dynamic>()),
                )
                .where(
                  (outfit) => outfit.items.every((id) => item(id) != null),
                ),
          );
      }
    } catch (_) {
      // The app remains usable if device storage is unavailable.
    }
    notifyListeners();
  }

  Outfit _sample(
    String id,
    String name,
    List<String> ids, [
    Map<String, String> sizes = const {},
  ]) {
    final outfit = Outfit(id: id, name: name, items: ids);
    for (final id in ids) {
      final garment = item(id)!;
      final size = sizes[id] ?? garment.defaultSize;
      outfit.settings[id] = GarmentSetting(
        colorId: garment.colors.first['id'] as String,
        size: size,
        measures: garment.measuresFor(size),
      );
    }
    return outfit;
  }

  void _changed({bool persist = false}) {
    notifyListeners();
    if (persist) _persist();
  }

  Future<void> _persist() async {
    try {
      await _saveFile?.writeAsString(
        jsonEncode({
          'wardrobe': wardrobe,
          'outfits': outfits.map((outfit) => outfit.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  void toggleFitting(String id) {
    if (fittingIds.contains(id)) {
      fittingIds.remove(id);
      if (activeId == id) activeId = fittingIds.firstOrNull;
    } else {
      fittingIds.add(id);
      activeId = id;
    }
    _changed();
  }

  void select(String id) {
    activeId = id;
    _changed();
  }

  void color(String id, String colorId) {
    settings[id]!.colorId = colorId;
    _changed();
  }

  void size(String id, String size) {
    settings[id]!.size = size;
    settings[id]!.measures = item(id)!.measuresFor(size);
    _changed();
  }

  void measure(String id, String key, double value) {
    settings[id]!.measures[key] = value;
    _changed();
  }

  void reset(String id) {
    settings[id]!.measures = item(id)!.measuresFor(settings[id]!.size);
    _changed();
  }

  void toggleWardrobe(String id) {
    if (wardrobe.contains(id)) {
      wardrobe.remove(id);
    } else {
      wardrobe.insert(0, id);
    }
    _changed(persist: true);
  }

  void saveOutfit(String name, List<String> ids, {String? existingId}) {
    if (existingId != null) {
      outfits.removeWhere((outfit) => outfit.id == existingId);
    }
    final outfit = Outfit(
      id: existingId ?? 'preset-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      items: [...ids],
    );
    for (final id in ids) {
      outfit.settings[id] = settings[id]!.copy();
    }
    outfits.insert(0, outfit);
    _changed(persist: true);
  }

  void updateOutfit(String id, String name, List<String> ids) {
    final outfit = outfits.firstWhere((outfit) => outfit.id == id);
    outfit.name = name;
    outfit.items = [...ids];
    outfit.settings.removeWhere((key, _) => !ids.contains(key));
    _changed(persist: true);
  }

  void loadOutfit(Outfit outfit) {
    fittingIds
      ..clear()
      ..addAll(outfit.items);
    for (final id in outfit.items) {
      settings[id] = outfit.settings[id]!.copy();
    }
    activeId = fittingIds.firstOrNull;
    _changed();
  }
}
