import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';

class CatalogGarmentImage extends StatelessWidget {
  const CatalogGarmentImage({super.key, required this.url, required this.name});
  final String? url;
  final String name;
  Widget _fallback() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.image_not_supported_outlined, color: faded),
        SizedBox(height: 6),
        Text('이미지 없음', style: TextStyle(color: faded, fontSize: 12)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: imageBackground,
    child: url == null
        ? _fallback()
        : Image.network(
            url!,
            fit: BoxFit.contain,
            semanticLabel: '$name 이미지',
            errorBuilder: (context, error, stack) => _fallback(),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
  );
}
