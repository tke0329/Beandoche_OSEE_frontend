import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:beandoche_osee_frontend/features/clothes/garment_api.dart';

Map<String, Object> garmentJson({
  int id = 7,
  String name = '테스트 셔츠',
  String image = '',
}) => {
  'id': id,
  'categoryId': 11,
  'categoryCode': 'SHIRT',
  'categoryName': '셔츠',
  'name': name,
  'thumbnailUrl': image,
};

Map<String, Object> garmentPageJson({
  int page = 0,
  int size = 20,
  int total = 0,
  List<Object> items = const [],
}) => {
  'content': items,
  'page': page,
  'size': size,
  'totalElements': total,
  'totalPages': (total / size).ceil(),
};

http.Response garmentResponse(Map<String, Object?> value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

GarmentApi emptyGarmentApi() => GarmentApi(
  client: MockClient(
    (request) async => garmentResponse(
      garmentPageJson(page: int.parse(request.url.queryParameters['page']!)),
    ),
  ),
);
