class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.children,
  });

  final int id;
  final String code;
  final String name;
  final List<CatalogCategory> children;

  factory CatalogCategory.fromJson(Object? value) {
    if (value case {
      'id': int id,
      'code': String code,
      'name': String name,
      'children': List<Object?> children,
    }) {
      if (id > 0 && code.trim().isNotEmpty && name.trim().isNotEmpty) {
        return CatalogCategory(
          id: id,
          code: code,
          name: name,
          children: List.unmodifiable(children.map(CatalogCategory.fromJson)),
        );
      }
    }
    throw const FormatException('Invalid category response');
  }

  Iterable<CatalogCategory> get descendants sync* {
    for (final child in children) {
      yield child;
      yield* child.descendants;
    }
  }
}
