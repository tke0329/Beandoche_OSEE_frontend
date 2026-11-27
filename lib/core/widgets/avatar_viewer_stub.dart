import 'package:flutter/widgets.dart';

import 'avatar_stage.dart';
import 'avatar_viewer.dart';

/// Non-web platforms show the static avatar image for both bodies.
Widget buildAvatarViewer(
  double height,
  AvatarModel model,
  int? heightMm,
  num? weightKg,
) => AvatarStage(height: height);
