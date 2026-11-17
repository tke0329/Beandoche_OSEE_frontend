import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// `web/viewer/avatar.html` is a plain file next to index.html, so it resolves against the base href.
Widget buildAvatarViewer(double height) => HtmlElementView.fromTagName(
  tagName: 'iframe',
  onElementCreated: (element) {
    final frame = element as web.HTMLIFrameElement;
    frame
      ..src = 'viewer/avatar.html'
      ..title = '3D 아바타'
      ..setAttribute('allowtransparency', 'true');
    frame.style
      ..border = 'none'
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = 'transparent';
  },
);
