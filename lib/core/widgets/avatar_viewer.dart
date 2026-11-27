import 'package:flutter/widgets.dart';

import 'avatar_viewer_stub.dart'
    if (dart.library.js_interop) 'avatar_viewer_web.dart'
    as platform;

/// Base body of the 3D avatar. [id] is what `web/viewer/avatar.html?model=` expects;
/// the GLB behind it must be listed under assets in pubspec.yaml.
enum AvatarModel {
  female('female', '여성'),
  male('male', '남성');

  const AvatarModel(this.id, this.label);
  final String id;
  final String label;
}

/// 3D avatar (three.js, `web/viewer/avatar.html`) on the web;
/// the static [AvatarStage] image on other platforms.
class AvatarViewer extends StatelessWidget {
  const AvatarViewer({
    super.key,
    required this.height,
    this.model = AvatarModel.female,
    this.heightMm,
    this.weightKg,
  });
  final double height;
  final AvatarModel model;
  final int? heightMm;
  final num? weightKg;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    // a new key rebuilds the iframe, so each body gets a fresh viewer
    child: KeyedSubtree(
      key: ValueKey(model),
      child: platform.buildAvatarViewer(height, model, heightMm, weightKg),
    ),
  );
}
