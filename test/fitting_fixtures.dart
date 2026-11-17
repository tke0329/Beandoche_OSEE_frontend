import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/features/clothes/garment_api.dart';

import 'garment_fixtures.dart';

Map<String, Object> detailJson({int id = 7}) => {
  ...garmentJson(id: id),
  'description': '서버 상품 설명',
};

Map<String, Object?> optionsJson() => {
  'materialStatus': 'UNKNOWN',
  'materials': [],
  'variants': [
    {
      'id': 71,
      'colorName': '화이트',
      'colorCode': 'WHITE',
      'colorHex': '#FFFFFF',
      'thumbnailUrl': null,
      'sizes': [
        {
          'id': 711,
          'garmentVariantId': 71,
          'sizeLabel': 'M',
          'sortOrder': 0,
          'sku': 'WHITE-M',
          'available': true,
        },
        {
          'id': 712,
          'garmentVariantId': 71,
          'sizeLabel': 'XL',
          'sortOrder': 1,
          'sku': 'WHITE-XL',
          'available': false,
        },
      ],
    },
    {
      'id': 72,
      'colorName': '블랙',
      'colorCode': 'BLACK',
      'colorHex': '#111111',
      'thumbnailUrl': null,
      'sizes': [
        {
          'id': 721,
          'garmentVariantId': 72,
          'sizeLabel': 'FREE',
          'sortOrder': 0,
          'sku': 'BLACK-FREE',
          'available': true,
        },
      ],
    },
  ],
  'measurementDefinitions': [
    {
      'id': 1,
      'code': 'CHEST_WIDTH',
      'name': '가슴단면',
      'defaultUnit': 'mm',
      'measurementBasis': 'FLAT_WIDTH',
      'description': '겨드랑이 아래 단면을 잽니다.',
      'active': true,
      'required': true,
      'displayOrder': 1,
      'fitAnalysisEnabled': true,
      'minValueMm': null,
      'maxValueMm': null,
    },
  ],
};

Map<String, Object?> selectionJson({
  int garmentId = 7,
  int variantId = 71,
  int sizeId = 711,
}) => {
  'garmentId': garmentId,
  'variantId': variantId,
  'sizeId': sizeId,
  'measurements': [
    {
      'definitionId': 1,
      'code': 'CHEST_WIDTH',
      'name': '가슴단면',
      'unit': 'mm',
      'measurementBasis': 'FLAT_WIDTH',
      'valueMm': 500,
      'source': 'DIRECT_MEASUREMENT',
      'measuredAt': '2026-01-01T00:00:00Z',
    },
  ],
  'validation': {
    'status': 'UNAVAILABLE',
    'measurementReady': false,
    'issues': [
      {
        'code': 'RANGE_NOT_CONFIGURED',
        'measurementCode': 'CHEST_WIDTH',
        'message': '허용 범위가 설정되지 않았습니다.',
      },
    ],
  },
  'model': {'status': 'NOT_PROVIDED', 'available': false},
};

GarmentApi fittingApi({void Function(http.Request)? onRequest}) => GarmentApi(
  client: MockClient((request) async {
    onRequest?.call(request);
    final path = request.url.path;
    final id = int.parse(path.split('/')[3]);
    if (path.endsWith('/options')) return garmentResponse(optionsJson());
    if (path.endsWith('/selection')) {
      return garmentResponse(
        selectionJson(
          garmentId: id,
          variantId: int.parse(request.url.queryParameters['variantId']!),
          sizeId: int.parse(request.url.queryParameters['sizeId']!),
        ),
      );
    }
    return garmentResponse(detailJson(id: id));
  }),
);
