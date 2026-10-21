import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/osee_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.image, this.radius = 24});
  final Uint8List? image;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: Container(
      width: radius * 2,
      height: radius * 2,
      color: OseePalette.primary100,
      child: image == null
          ? Icon(
              Icons.person_outline,
              color: OseePalette.primary700,
              size: radius * 1.25,
            )
          : Image.memory(
              image!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Icon(
                Icons.person_outline,
                color: OseePalette.primary700,
                size: radius * 1.25,
              ),
            ),
    ),
  );
}
