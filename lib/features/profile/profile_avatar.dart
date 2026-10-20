import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.image, this.radius = 24});
  final Uint8List? image;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: Container(
      width: radius * 2,
      height: radius * 2,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: image == null
          ? Icon(Icons.person_outline, size: radius * 1.1)
          : Image.memory(
              image!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.person_outline, size: radius * 1.1),
            ),
    ),
  );
}
