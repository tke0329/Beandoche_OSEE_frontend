class Garment {
  Garment(this.raw);
  final Map<String, dynamic> raw;

  String get id => raw['id'] as String;
  String get name => raw['name'] as String;
  String get category => raw['category'] as String;
  String get sub => raw['sub'] as String;
  String get image => 'assets/images/${(raw['image'] as String).substring(1)}';
  List<Map<String, dynamic>> get colors =>
      (raw['colors'] as List).cast<Map<String, dynamic>>();
  List<String> get sizes => (raw['sizes'] as List).cast<String>();
  String get defaultSize => raw['defaultSize'] as String;
  List<Map<String, dynamic>> get fields =>
      (raw['fields'] as List).cast<Map<String, dynamic>>();
  List<String> get details => (raw['details'] as List).cast<String>();

  Map<String, double> measuresFor(String size) {
    final diff = sizes.indexOf(size) - sizes.indexOf(defaultSize);
    final base = raw['base'] as Map<String, dynamic>;
    final step = raw['step'] as Map<String, dynamic>;
    return {
      for (final field in fields)
        field['key'] as String:
            (((base[field['key']] as num) +
                        ((step[field['key']] as num?) ?? 0) * diff) *
                    10)
                .round() /
            10,
    };
  }
}

class GarmentSetting {
  GarmentSetting({
    required this.colorId,
    required this.size,
    required this.measures,
  });
  String colorId;
  String size;
  Map<String, double> measures;

  factory GarmentSetting.initial(Garment item) => GarmentSetting(
    colorId: item.colors.first['id'] as String,
    size: item.defaultSize,
    measures: item.measuresFor(item.defaultSize),
  );

  factory GarmentSetting.fromJson(Map<String, dynamic> json) => GarmentSetting(
    colorId: json['colorId'] as String,
    size: json['size'] as String,
    measures: (json['measures'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    ),
  );

  Map<String, dynamic> toJson() => {
    'colorId': colorId,
    'size': size,
    'measures': measures,
  };
  GarmentSetting copy() =>
      GarmentSetting(colorId: colorId, size: size, measures: {...measures});
}
