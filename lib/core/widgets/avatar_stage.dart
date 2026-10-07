import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';

import 'package:flutter/material.dart';

class AvatarStage extends StatelessWidget {
  const AvatarStage({super.key, this.height, this.showPlatform = true});
  final double? height;
  final bool showPlatform;

  @override
  Widget build(BuildContext context) {
    final stageHeight =
        height ?? (MediaQuery.sizeOf(context).width >= 1050 ? 620.0 : 390.0);
    final figureHeight = stageHeight >= 600 ? 560.0 : stageHeight * .82;
    return SizedBox(
      height: stageHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (showPlatform)
            Positioned(
              bottom: stageHeight >= 600 ? 8 : 25,
              child: Container(
                width: stageHeight >= 600 ? 387 : 270,
                height: stageHeight >= 600 ? 78 : 38,
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: OseePalette.tertiary500),
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(
                      stageHeight >= 600 ? 194 : 135,
                      stageHeight >= 600 ? 39 : 19,
                    ),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: OseePalette.shadowMedium,
                      blurRadius: 3,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: stageHeight >= 600 ? 18 : 32,
            child: Transform.translate(
              offset: Offset(stageHeight >= 600 ? 14 : 0, 0),
              child: ReferenceAvatar(height: figureHeight),
            ),
          ),
        ],
      ),
    );
  }
}

class ReferenceAvatar extends StatelessWidget {
  const ReferenceAvatar({super.key, required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    final scale = height / 560;
    return SizedBox(
      width: 350 * scale,
      height: height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -205 * scale,
              top: -130 * scale,
              width: 1280 * scale,
              height: 832 * scale,
              child: Image.asset(
                'assets/images/design_avatar.png',
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
