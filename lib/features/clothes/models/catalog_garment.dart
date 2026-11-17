class CatalogGarment {
  const CatalogGarment({
    required this.id,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.name,
    required this.thumbnailUrl,
  });

  final int id;
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final String name;
  final String thumbnailUrl;

  factory CatalogGarment.fromJson(Object? value) {
    if (value case {
      'id': int id,
      'categoryId': int categoryId,
      'categoryCode': String categoryCode,
      'categoryName': String categoryName,
      'name': String name,
      'thumbnailUrl': String thumbnailUrl,
    }) {
      if (id > 0 &&
          categoryId > 0 &&
          categoryCode.trim().isNotEmpty &&
          categoryName.trim().isNotEmpty &&
          name.trim().isNotEmpty) {
        return CatalogGarment(
          id: id,
          categoryId: categoryId,
          categoryCode: categoryCode,
          categoryName: categoryName,
          name: name,
          thumbnailUrl: thumbnailUrl,
        );
      }
    }
    throw const FormatException('Invalid garment response');
  }
}

class GarmentPage {
  const GarmentPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<CatalogGarment> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory GarmentPage.fromJson(Object? value) {
    if (value case {
      'content': List<Object?> content,
      'page': int page,
      'size': int size,
      'totalElements': int totalElements,
      'totalPages': int totalPages,
    }) {
      if (page >= 0 &&
          size > 0 &&
          size <= 100 &&
          totalElements >= 0 &&
          totalPages == (totalElements / size).ceil() &&
          content.length <= size &&
          content.length <= totalElements) {
        return GarmentPage(
          content: List.unmodifiable(content.map(CatalogGarment.fromJson)),
          page: page,
          size: size,
          totalElements: totalElements,
          totalPages: totalPages,
        );
      }
    }
    throw const FormatException('Invalid garment page');
  }
}
