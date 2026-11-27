enum BodyMeasurement {
  height('heightMm', '키'),
  weight('weightKg', '몸무게'),
  chest('chestCircumferenceMm', '가슴둘레'),
  waist('waistCircumferenceMm', '허리둘레'),
  hip('hipCircumferenceMm', '엉덩이둘레'),
  thigh('thighCircumferenceMm', '허벅지둘레'),
  underbust('underbustCircumferenceMm', '밑가슴둘레');

  const BodyMeasurement(this.key, this.label);
  final String key;
  final String label;
  bool get isLength => this != weight;
  bool get isRequired => this != underbust;
  bool get _usesInches => isLength && this != height;
  bool get isMorphDimension => _usesInches && this != underbust;
  String get unit => _usesInches ? 'in' : (isLength ? 'cm' : 'kg');
  int get decimalPlaces => _usesInches ? 2 : (isLength ? 1 : 3);
  double get _unitsFactor => _usesInches ? 25.4 : (isLength ? 10 : 1);
  double inputUnits(num value) => value / _unitsFactor;

  num? parseInput(String input) {
    final text = input.trim();
    final pattern = RegExp('^\\d+(?:\\.\\d{1,$decimalPlaces})?\$');
    if (!pattern.hasMatch(text)) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite || value <= 0) return null;
    if (!isLength) return value < 100000 ? value : null;
    final length = value * _unitsFactor;
    if (length > 1000000000) return null;
    final mm = length.round();
    return mm > 0 && mm <= 999999999 ? mm : null;
  }

  String display(num value) {
    final text = inputUnits(value).toStringAsFixed(decimalPlaces);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class BodyMeasurements {
  BodyMeasurements(Map<BodyMeasurement, num> values)
    : values = Map.unmodifiable(values) {
    for (final field in BodyMeasurement.values) {
      final value = values[field];
      if (value == null && !field.isRequired) continue;
      if (value == null ||
          !value.isFinite ||
          value <= 0 ||
          (field.isLength && (value != value.round() || value > 999999999)) ||
          (!field.isLength && value >= 100000)) {
        throw const FormatException('Invalid body measurement');
      }
    }
    final band = values[BodyMeasurement.underbust];
    if (band != null && band >= values[BodyMeasurement.chest]!) {
      throw const FormatException('Invalid underbust');
    }
  }

  final Map<BodyMeasurement, num> values;

  Map<String, num> get morphDimensionsMm => {
    for (final field in BodyMeasurement.values)
      if (field.isMorphDimension) field.key: values[field]!,
  };

  factory BodyMeasurements.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Invalid body measurements');
    }
    final values = <BodyMeasurement, num>{};
    for (final field in BodyMeasurement.values) {
      final value = json[field.key];
      if (value == null && !field.isRequired) continue;
      if (value is! num) throw const FormatException('Invalid measurement');
      values[field] = value;
    }
    return BodyMeasurements(values);
  }

  Map<String, num> toJson() => {
    for (final field in values.keys) field.key: values[field]!,
  };
}

// Reference differences for the preview, based on the Wacoal A–F size guide.
enum BustCup {
  a('A', 100),
  b('B', 125),
  c('C', 150),
  d('D', 175),
  e('E', 200),
  f('F', 225);

  const BustCup(this.label, this.differenceMm);
  final String label;
  final int differenceMm;

  static BustCup? fromMeasurements(num? bustMm, num? bandMm) {
    if (bustMm == null || bandMm == null) return null;
    final difference = bustMm - bandMm;
    for (final cup in values) {
      if ((difference - cup.differenceMm).abs() <= 12.5) return cup;
    }
    return null;
  }
}

class BodyProfile {
  const BodyProfile({
    required this.gender,
    required this.measurements,
    required this.version,
    required this.generationId,
    required this.status,
  });

  final String? gender;
  final BodyMeasurements measurements;
  final int version;
  final String generationId;
  final String status;

  factory BodyProfile.fromJson(Object? json) {
    if (json case {
      'gender': final String? gender,
      'bodyVersion': final int version,
      'generationId': final String id,
      'generationStatus': final String status,
      'measurements': final Object measurements,
    }) {
      if (version > 0 &&
          id.isNotEmpty &&
          const {
            'PENDING',
            'PROCESSING',
            'COMPLETED',
            'FAILED',
          }.contains(status)) {
        return BodyProfile(
          gender: gender,
          measurements: BodyMeasurements.fromJson(measurements),
          version: version,
          generationId: id,
          status: status,
        );
      }
    }
    throw const FormatException('Invalid body profile');
  }
}
