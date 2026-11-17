import 'package:flutter/widgets.dart';

import 'avatar_viewer_stub.dart'
    if (dart.library.js_interop) 'avatar_viewer_web.dart'
    as platform;

/// 3D avatar (three.js, `web/viewer/avatar.html`) on the web;
/// the static [AvatarStage] image on other platforms.
class AvatarViewer extends StatelessWidget {
  const AvatarViewer({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height, child: platform.buildAvatarViewer(height));
}
