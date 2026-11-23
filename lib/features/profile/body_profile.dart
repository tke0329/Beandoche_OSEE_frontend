enum BodyMeasurement {
  height('heightMm', '키'),
  weight('weightKg', '몸무게'),
  chest('chestCircumferenceMm', '가슴둘레'),
  waist('waistCircumferenceMm', '허리둘레'),
  hip('hipCircumferenceMm', '엉덩이둘레'),
  thigh('thighCircumferenceMm', '허벅지둘레'),
  inseam('inseamMm', '인심 길이');

  const BodyMeasurement(this.key, this.label);
  final String key;
  final String label;
  bool get isLength => this != weight;
  String get unit => isLength ? 'cm' : 'kg';

  num? parseInput(String input) {
    final text = input.trim();
    final pattern = isLength
        ? RegExp(r'^\d+(?:\.\d)?$')
        : RegExp(r'^\d+(?:\.\d{1,3})?$');
    if (!pattern.hasMatch(text)) return null;
    if (!isLength) {
      final value = double.tryParse(text);
      return value != null && value > 0 && value < 100000 ? value : null;
    }
    final parts = text.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null || whole > 99999999) return null;
    final mm = whole * 10 + (parts.length == 2 ? int.parse(parts[1]) : 0);
    return mm > 0 && mm <= 999999999 ? mm : null;
  }

  String display(num value) {
    final text = (isLength ? value / 10 : value).toStringAsFixed(
      isLength ? 1 : 3,
    );
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class BodyMeasurements {
  BodyMeasurements(Map<BodyMeasurement, num> values)
    : values = Map.unmodifiable(values) {
    for (final field in BodyMeasurement.values) {
      final value = values[field];
      if (value == null ||
          !value.isFinite ||
          value <= 0 ||
          (field.isLength && (value != value.round() || value > 999999999)) ||
          (!field.isLength && value >= 100000)) {
        throw const FormatException('Invalid body measurement');
      }
    }
  }

  final Map<BodyMeasurement, num> values;

  factory BodyMeasurements.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Invalid body measurements');
    }
    final values = <BodyMeasurement, num>{};
    for (final field in BodyMeasurement.values) {
      final value = json[field.key];
      if (value is! num) throw const FormatException('Invalid measurement');
      values[field] = value;
    }
    return BodyMeasurements(values);
  }

  Map<String, num> toJson() => {
    for (final field in BodyMeasurement.values) field.key: values[field]!,
  };
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
