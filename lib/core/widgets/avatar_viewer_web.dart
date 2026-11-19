import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'avatar_viewer.dart';

/// `web/viewer/avatar.html` is a plain file next to index.html, so it resolves against the base href.
Widget buildAvatarViewer(double height, AvatarModel model) =>
    HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (element) {
        final frame = element as web.HTMLIFrameElement;
        frame
          ..src = 'viewer/avatar.html?model=${model.id}'
          ..title = '3D 아바타 (${model.label})'
          ..setAttribute('allowtransparency', 'true');
        frame.style
          ..border = 'none'
          ..width = '100%'
          ..height = '100%'
          ..backgroundColor = 'transparent';
      },
    );
