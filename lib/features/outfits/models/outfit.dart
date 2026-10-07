import 'package:beandoche_osee_frontend/features/clothes/models/garment.dart';

class Outfit {
  Outfit({required this.id, required this.name, required this.items});
  final String id;
  String name;
  List<String> items;
  Map<String, GarmentSetting> settings = {};

  factory Outfit.fromJson(Map<String, dynamic> json) {
    final outfit = Outfit(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List).map((e) => e['id'] as String).toList(),
    );
    for (final entry in json['items'] as List) {
      final value = entry as Map<String, dynamic>;
      outfit.settings[value['id'] as String] = GarmentSetting.fromJson(value);
    }
    return outfit;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': [
      for (final id in items) {'id': id, ...settings[id]!.toJson()},
    ],
  };
}
