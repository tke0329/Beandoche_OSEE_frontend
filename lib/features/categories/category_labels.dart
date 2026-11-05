String categoryLabel(String code, String fallback) => switch (code) {
  'TOP' => 'Top',
  'OUTERWEAR' => 'Outerwear',
  'PANTS' => 'Pants',
  'DRESS_SKIRT' => 'Dress/Skirt',
  _ => fallback,
};
