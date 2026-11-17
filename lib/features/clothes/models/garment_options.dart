import 'catalog_garment.dart';

Map<String, Object?> catalogMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw const FormatException('Invalid catalog object');
}

List<T> catalogList<T>(Object? value, T Function(Object?) parse) {
  if (value is List<Object?>) return List.unmodifiable(value.map(parse));
  throw const FormatException('Invalid catalog list');
}

String catalogString(Object? value) {
  if (value is String) return value;
  throw const FormatException('Invalid catalog text');
}

int catalogId(Object? value) {
  if (value is int && value > 0) return value;
  throw const FormatException('Invalid catalog ID');
}

class GarmentSize {
  const GarmentSize(this.id, this.variantId, this.label, this.available);
  final int id;
  final int variantId;
  final String label;
  final bool available;
  factory GarmentSize.fromJson(Object? value) {
    final m = catalogMap(value);
    if (m['available'] is! bool) {
      throw const FormatException('Invalid availability');
    }
    return GarmentSize(
      catalogId(m['id']),
      catalogId(m['garmentVariantId']),
      catalogString(m['sizeLabel']),
      m['available'] as bool,
    );
  }
}

class GarmentVariant {
  const GarmentVariant(
    this.id,
    this.name,
    this.code,
    this.hex,
    this.thumbnailUrl,
    this.sizes,
  );
  final int id;
  final String name;
  final String code;
  final String? hex;
  final String? thumbnailUrl;
  final List<GarmentSize> sizes;
  factory GarmentVariant.fromJson(Object? value) {
    final m = catalogMap(value);
    final hex = m['colorHex'];
    if (hex != null &&
        (hex is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex))) {
      throw const FormatException('Invalid color');
    }
    final thumbnail = m['thumbnailUrl'];
    if (thumbnail != null && thumbnail is! String) {
      throw const FormatException('Invalid image');
    }
    final id = catalogId(m['id']);
    final sizes = catalogList(m['sizes'], GarmentSize.fromJson);
    if (sizes.any((size) => size.variantId != id)) {
      throw const FormatException('Unrelated size');
    }
    return GarmentVariant(
      id,
      catalogString(m['colorName']),
      catalogString(m['colorCode']),
      hex as String?,
      thumbnail as String?,
      sizes,
    );
  }
}

class MaterialShare {
  const MaterialShare(this.name, this.percentage);
  final String name;
  final num percentage;
  factory MaterialShare.fromJson(Object? value) {
    final m = catalogMap(value);
    final percentage = m['percentage'];
    if (percentage is! num ||
        !percentage.isFinite ||
        percentage <= 0 ||
        percentage > 100) {
      throw const FormatException('Invalid composition');
    }
    return MaterialShare(catalogString(m['name']), percentage);
  }
}

class MeasurementRule {
  const MeasurementRule(
    this.id,
    this.code,
    this.name,
    this.unit,
    this.basis,
    this.description,
    this.required,
    this.displayOrder,
    this.fitEnabled,
    this.minMm,
    this.maxMm,
  );
  final int id;
  final String code;
  final String name;
  final String unit;
  final String basis;
  final String description;
  final bool required;
  final int displayOrder;
  final bool fitEnabled;
  final num? minMm;
  final num? maxMm;
  factory MeasurementRule.fromJson(Object? value) {
    final m = catalogMap(value);
    if (m['required'] is! bool ||
        m['fitAnalysisEnabled'] is! bool ||
        m['displayOrder'] is! int ||
        (m['minValueMm'] != null && m['minValueMm'] is! num) ||
        (m['maxValueMm'] != null && m['maxValueMm'] is! num)) {
      throw const FormatException('Invalid rule');
    }
    return MeasurementRule(
      catalogId(m['id']),
      catalogString(m['code']),
      catalogString(m['name']),
      catalogString(m['defaultUnit']),
      catalogString(m['measurementBasis']),
      catalogString(m['description']),
      m['required'] as bool,
      m['displayOrder'] as int,
      m['fitAnalysisEnabled'] as bool,
      m['minValueMm'] as num?,
      m['maxValueMm'] as num?,
    );
  }
}

class GarmentOptions {
  const GarmentOptions(
    this.materialStatus,
    this.materials,
    this.variants,
    this.rules,
  );
  final String materialStatus;
  final List<MaterialShare> materials;
  final List<GarmentVariant> variants;
  final List<MeasurementRule> rules;
  factory GarmentOptions.fromJson(Object? value) {
    final m = catalogMap(value);
    final status = catalogString(m['materialStatus']);
    if (!['UNKNOWN', 'KNOWN'].contains(status)) {
      throw const FormatException('Invalid material status');
    }
    final materials = catalogList(m['materials'], MaterialShare.fromJson);
    if (status == 'KNOWN' &&
        (materials.fold<num>(0, (sum, share) => sum + share.percentage) - 100)
                .abs() >
            .001) {
      throw const FormatException('Invalid composition total');
    }
    return GarmentOptions(
      status,
      materials,
      catalogList(m['variants'], GarmentVariant.fromJson),
      catalogList(m['measurementDefinitions'], MeasurementRule.fromJson),
    );
  }
}

class GarmentDetails {
  const GarmentDetails(this.garment, this.description, this.options);
  final CatalogGarment garment;
  final String description;
  final GarmentOptions options;
  factory GarmentDetails.fromJson(Object? common, Object? options) {
    final m = catalogMap(common);
    return GarmentDetails(
      CatalogGarment.fromJson(common),
      catalogString(m['description']),
      GarmentOptions.fromJson(options),
    );
  }
}

class SizeMeasurement {
  const SizeMeasurement(
    this.definitionId,
    this.code,
    this.name,
    this.unit,
    this.basis,
    this.valueMm,
    this.source,
    this.measuredAt,
  );
  final int definitionId;
  final String code;
  final String name;
  final String unit;
  final String basis;
  final num valueMm;
  final String source;
  final DateTime measuredAt;
  factory SizeMeasurement.fromJson(Object? value) {
    final m = catalogMap(value);
    final mm = m['valueMm'];
    if (mm is! num || !mm.isFinite || mm <= 0) {
      throw const FormatException('Invalid measurement');
    }
    return SizeMeasurement(
      catalogId(m['definitionId']),
      catalogString(m['code']),
      catalogString(m['name']),
      catalogString(m['unit']),
      catalogString(m['measurementBasis']),
      mm,
      catalogString(m['source']),
      DateTime.parse(catalogString(m['measuredAt'])),
    );
  }
  String get displayValue => unit == 'mm'
      ? '${formatNumber(valueMm / 10)} cm'
      : '${formatNumber(valueMm)} $unit';
}

String formatNumber(num value) =>
    value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');

class MeasurementIssue {
  const MeasurementIssue(this.code, this.measurementCode, this.message);
  final String code;
  final String? measurementCode;
  final String message;
  factory MeasurementIssue.fromJson(Object? value) {
    final m = catalogMap(value);
    final measurementCode = m['measurementCode'];
    if (measurementCode != null && measurementCode is! String) {
      throw const FormatException('Invalid issue');
    }
    return MeasurementIssue(
      catalogString(m['code']),
      measurementCode as String?,
      catalogString(m['message']),
    );
  }
}

class GarmentSelection {
  const GarmentSelection(
    this.garmentId,
    this.variantId,
    this.sizeId,
    this.measurements,
    this.validationStatus,
    this.measurementReady,
    this.issues,
    this.modelAvailable,
  );
  final int garmentId;
  final int variantId;
  final int sizeId;
  final List<SizeMeasurement> measurements;
  final String validationStatus;
  final bool measurementReady;
  final List<MeasurementIssue> issues;
  final bool modelAvailable;
  factory GarmentSelection.fromJson(Object? value) {
    final m = catalogMap(value);
    final validation = catalogMap(m['validation']);
    final model = catalogMap(m['model']);
    final status = catalogString(validation['status']);
    if (!['VALID', 'INVALID', 'UNAVAILABLE'].contains(status) ||
        validation['measurementReady'] is! bool ||
        model['available'] is! bool ||
        validation['measurementReady'] != (status == 'VALID')) {
      throw const FormatException('Invalid validation');
    }
    return GarmentSelection(
      catalogId(m['garmentId']),
      catalogId(m['variantId']),
      catalogId(m['sizeId']),
      catalogList(m['measurements'], SizeMeasurement.fromJson),
      status,
      validation['measurementReady'] as bool,
      catalogList(validation['issues'], MeasurementIssue.fromJson),
      model['available'] as bool,
    );
  }
}
